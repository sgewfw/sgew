const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const path = require("path");

admin.initializeApp();

const bucket = admin.storage().bucket();

// ==========================================================
// Konfiguration
// ==========================================================
const SMAPONE_BASE_URL = "https://platform.smapone.com/Backend/v1";
const SMAP_ID = "c3add719-513a-4a68-86ea-24e8429b2cd6";

function getAccessToken() {
  return process.env.SMAPONE_ACCESS_TOKEN || "";
}

function getSyncSecret() {
  return process.env.SYNC_SECRET || "";
}

function getAuthHeader() {
  const token = getAccessToken();
  const credentials = Buffer.from(`X:${token}`).toString("base64");
  return `Basic ${credentials}`;
}

const SCHWEREGRAD_MAP = {
  kritisch: "kritisch",
  mittel: "mittel",
  gering: "gering",
};

const STANDARD_FRISTEN = {
  kritisch: 1,
  mittel: 7,
  gering: 30,
};

const BEGEHUNG_TYP_MAP = {
  begehungsprotokoll: "Standardbegehung",
  baustellenbegehung: "Baustellenbegehung",
  sicherheitsbegehung: "Sicherheitsbegehung",
  fremdfirmenbegehung: "Fremdfirmenbegehung",
};

// ==========================================================
// Scheduled Polling — Alle 8 Stunden neue Begehungen holen
// ==========================================================
exports.pollSmapOneBegehungen = onSchedule(
  {
    schedule: "every 8 hours",
    timeZone: "Europe/Berlin",
    region: "europe-west1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    console.log("🔄 SmapOne Polling gestartet (Scheduled)...");
    const result = await syncSmapOneData(true);
    console.log(
      `✅ Scheduled Sync: ${result.imported} importiert, ${result.skipped} übersprungen.`
    );
  }
);

// ==========================================================
// Callable Function — User kann manuell refreshen aus der App
// ==========================================================
exports.syncBegehungen = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Nur eingeloggte User können synchronisieren."
      );
    }

    console.log(`🔄 Manueller Sync von User: ${request.auth.uid}`);

    try {
      const result = await syncSmapOneData(true);
      return {
        success: true,
        imported: result.imported,
        skipped: result.skipped,
        errors: result.errors,
      };
    } catch (error) {
      console.error("❌ Manueller Sync Fehler:", error);
      throw new HttpsError("internal", error.message);
    }
  }
);

// ==========================================================
// HTTP-Trigger zum Testen (z.B. via curl)
// ==========================================================
exports.triggerSmapOneSync = onRequest(
  {
    region: "europe-west1",
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (req, res) => {
    const secret = req.headers["x-sync-secret"];
    if (secret !== getSyncSecret()) {
      return res.status(401).send("Unauthorized");
    }

    try {
      const testMode = req.query.test === "true";
      const result = await syncSmapOneData(!testMode);
      return res.status(200).json({ success: true, ...result });
    } catch (error) {
      console.error("Sync Fehler:", error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
);

// ==========================================================
// Kern-Logik: SmapOne Daten synchronisieren
// ==========================================================
async function syncSmapOneData(markAsExported = true) {
  const records = await fetchNewRecords(markAsExported);

  if (!records || records.length === 0) {
    console.log("✅ Keine neuen Begehungen gefunden.");
    return { imported: 0, skipped: 0, errors: 0 };
  }

  console.log(`📋 ${records.length} neue Begehung(en) gefunden.`);

  let imported = 0;
  let skipped = 0;
  let errors = 0;

  for (const record of records) {
    try {
      const result = await processBegehungsRecord(record);
      if (result.wasSkipped) {
        skipped++;
      } else {
        imported++;
      }
    } catch (err) {
      console.error(`❌ Fehler bei Begehung ${record.id}:`, err);
      errors++;
    }
  }

  return { imported, skipped, errors };
}

// ==========================================================
// SmapOne API — Neue Datensätze abrufen
// ==========================================================
async function fetchNewRecords(markAsExported = true) {
  const url =
    `${SMAPONE_BASE_URL}/Smaps/${SMAP_ID}/Versions/Current/Data` +
    `?markAsExported=${markAsExported}&format=Json&state=New`;

  console.log(
    `📡 SmapOne API: state=New, markAsExported=${markAsExported}`
  );

  const response = await fetch(url, {
    headers: {
      Authorization: getAuthHeader(),
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`SmapOne API Fehler ${response.status}: ${errorText}`);
  }

  const data = await response.json();

  if (Array.isArray(data)) return data;
  if (data.records && Array.isArray(data.records)) return data.records;
  if (data.id) return [data];

  console.warn(
    "⚠️ Unerwartetes API-Format:",
    JSON.stringify(data).substring(0, 200)
  );
  return [];
}

// ==========================================================
// Foto von SmapOne herunterladen und in Firebase Storage speichern
// ==========================================================
async function downloadAndStorePhoto(smapOneUrl, begehungId, mangelId, photoName) {
  if (!smapOneUrl) return null;

  try {
    // Foto von SmapOne API herunterladen (mit Auth)
    const response = await fetch(smapOneUrl, {
      headers: {
        Authorization: getAuthHeader(),
      },
    });

    if (!response.ok) {
      console.warn(`⚠️ Foto Download fehlgeschlagen (${response.status}): ${smapOneUrl}`);
      return null;
    }

    const contentType = response.headers.get("content-type") || "image/jpeg";
    const buffer = await response.buffer();

    // In Firebase Storage speichern
    const storagePath = `begehungen/${begehungId}/maengel/${mangelId}/${photoName}`;
    const file = bucket.file(storagePath);

    // Download-Token generieren (wie Firebase Console es macht)
    const { v4: uuidv4 } = require("uuid");
    const downloadToken = uuidv4();

    await file.save(buffer, {
      metadata: {
        contentType: contentType,
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
          source: "smapone",
        },
      },
    });

    // Öffentliche Download-URL im Firebase-Format
    const bucketName = bucket.name;
    const encodedPath = encodeURIComponent(storagePath);
    const downloadUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media&token=${downloadToken}`;

    console.log(`📸 Foto gespeichert: ${storagePath}`);
    return downloadUrl;
  } catch (error) {
    console.error(`❌ Foto-Upload Fehler für ${photoName}:`, error.message);
    return null;
  }
}

// ==========================================================
// Einzelnen SmapOne-Record verarbeiten
// ==========================================================
async function processBegehungsRecord(record) {
  const db = admin.firestore();
  const smapData = record.data;

  // 1. Duplikat-Check
  const existingSnap = await db
    .collection("begehungen")
    .where("smapone_report_id", "==", record.id)
    .limit(1)
    .get();

  if (!existingSnap.empty) {
    console.log(`⏭️ Begehung ${record.id} bereits importiert.`);
    return { begehungId: existingSnap.docs[0].id, wasSkipped: true };
  }

  // 2. Ersteller per Email suchen
  const erstellerEmail = (record.userEmail || "").toLowerCase().trim();
  let erstellerDoc = null;

  if (erstellerEmail) {
    const userSnap = await db
      .collection("users")
      .where("email", "==", erstellerEmail)
      .limit(1)
      .get();

    if (!userSnap.empty) {
      erstellerDoc = { id: userSnap.docs[0].id, ...userSnap.docs[0].data() };
    }
  }

  // 3. Felder extrahieren
  const typ = mapBegehungTyp(smapData.Select_2);
  const ort = smapData.DataRecordSelect?.Ort || "";
  const standortBezeichnung =
    smapData.DataRecordSelect?.Bezeichnung || "";
  const standortStrasse = smapData.DataRecordSelect?.Strasse || "";
  const standortPlz = smapData.DataRecordSelect?.Postleitzahl || "";
  const erstellerName = smapData.Textbox_5 || record.userName || "";
  const datum = parseDatum(smapData.DateTime_2 || record.sendDate);
  const berichtsText = smapData.Textbox_6 || "";
  const berichtsKategorie = smapData.Textbox_8 || "";

  // Abteilung + Standort aus Firestore-User-Profil
  const abteilung = erstellerDoc?.abteilung || "";
  const standort = erstellerDoc?.standort || "";
  const erstellerUid = erstellerDoc?.uid || erstellerDoc?.id || "";

  // 4. Mängel extrahieren
  const maengel = extractMaengel(smapData);

  // 5. Begehung speichern
  const begehungRef = db.collection("begehungen").doc();
  const timestamp = admin.firestore.Timestamp.now();

  await begehungRef.set({
    typ: typ,
    datum: admin.firestore.Timestamp.fromDate(datum),
    ort: ort,
    standort: standort,
    standort_bezeichnung: standortBezeichnung,
    standort_strasse: standortStrasse,
    standort_plz: standortPlz,
    abteilung: abteilung,
    ersteller_uid: erstellerUid,
    ersteller_name: erstellerName,
    ersteller_email: erstellerEmail,
    berichtsText: berichtsText,
    berichtsKategorie: berichtsKategorie,
    anzahlMaengel: maengel.length,
    offeneMaengel: maengel.length,
    behobeneMaengel: 0,
    smapone_report_id: record.id,
    smapone_version: record.version || "",
    created_at: timestamp,
  });

  // 6. Mängel als Subcollection speichern (mit Foto-Download)
  for (let i = 0; i < maengel.length; i++) {
    const mangel = maengel[i];
    const mangelRef = begehungRef.collection("maengel").doc();

    // Fotos von SmapOne herunterladen und in Firebase Storage speichern
    const fotoUrl = await downloadAndStorePhoto(
      mangel.fotoUrl,
      begehungRef.id,
      mangelRef.id,
      `foto_${i + 1}.jpg`
    );
    const fotoUrl2 = await downloadAndStorePhoto(
      mangel.fotoUrl2,
      begehungRef.id,
      mangelRef.id,
      `foto_${i + 1}_2.jpg`
    );

    // Zuständige Person auflösen
    let zustaendigUid = erstellerUid;
    let zustaendigName = erstellerName;
    let zustaendigEmail = erstellerEmail;

    if (mangel.zustaendigEmail) {
      const zEmail = mangel.zustaendigEmail.toLowerCase().trim();
      const zustaendigSnap = await db
        .collection("users")
        .where("email", "==", zEmail)
        .limit(1)
        .get();

      if (!zustaendigSnap.empty) {
        const zDoc = zustaendigSnap.docs[0].data();
        zustaendigUid = zDoc.uid || zustaendigSnap.docs[0].id;
        zustaendigName = zDoc.name || mangel.zustaendigName || "";
      } else {
        zustaendigName = mangel.zustaendigName || erstellerName;
      }
      zustaendigEmail = zEmail;
    }

    // Frist berechnen
    const schweregrad = mangel.schweregrad || "mittel";
    let frist;
    if (mangel.frist) {
      frist = admin.firestore.Timestamp.fromDate(new Date(mangel.frist));
    } else {
      const tage = STANDARD_FRISTEN[schweregrad] || 7;
      const d = new Date(datum);
      d.setDate(d.getDate() + tage);
      frist = admin.firestore.Timestamp.fromDate(d);
    }

    await mangelRef.set({
      id: mangelRef.id,
      begehungId: begehungRef.id,
      beschreibung: mangel.beschreibung || "",
      kategorie: mangel.kategorie || "sonstiges",
      schweregrad: schweregrad,
      fotoUrl: fotoUrl,
      fotoUrl2: fotoUrl2,
      ortNotiz: mangel.ortNotiz || null,
      frist: frist,
      status: "offen",
      zustaendig_uid: zustaendigUid,
      zustaendig_name: zustaendigName,
      zustaendig_email: zustaendigEmail,
      behoben_von_uid: null,
      behoben_am: null,
      erinnerung_gesendet: false,
      created_at: timestamp,
    });

    // Zuständigen User Counter hochzählen
    if (zustaendigUid) {
      const userRef = db.collection("users").doc(zustaendigUid);
      const userDoc = await userRef.get();
      if (userDoc.exists) {
        await userRef.update({
          offeneMaengel: admin.firestore.FieldValue.increment(1),
        });
      }
    }
  }

  // 7. Counter aktualisieren
  const batch = db.batch();

  if (erstellerUid) {
    const userRef = db.collection("users").doc(erstellerUid);
    batch.update(userRef, {
      begehungenDiesesJahr: admin.firestore.FieldValue.increment(1),
    });
  }

  if (abteilung) {
    const abteilungSnap = await db
      .collection("abteilungen")
      .where("name", "==", abteilung)
      .limit(1)
      .get();

    if (!abteilungSnap.empty) {
      batch.update(abteilungSnap.docs[0].ref, {
        begehungenDiesesJahr: admin.firestore.FieldValue.increment(1),
        offeneMaengel: admin.firestore.FieldValue.increment(maengel.length),
      });
    }
  }

  await batch.commit();

  console.log(
    `✅ Begehung ${begehungRef.id}: ${ort}, ${maengel.length} Mängel, Ersteller: ${erstellerName}`
  );

  return { begehungId: begehungRef.id, wasSkipped: false };
}

// ==========================================================
// Mängel aus RepeatGroup extrahieren
// ==========================================================
function extractMaengel(smapData) {
  const repeatGroup = smapData.RepeatGroup;
  if (!repeatGroup || !Array.isArray(repeatGroup) || repeatGroup.length === 0) {
    return [];
  }

  return repeatGroup
    .map((item) => {
      if (!item.Photo && !item.Photo_description && !item.Textbox_9) {
        return null;
      }

      const beschreibung =
        item.Photo_description || item.Textbox_9 || "Mangel ohne Beschreibung";
      const ortNotiz = item.Textbox_9 || null;
      const schwerегradRaw = (item.Photos_Select || "mittel").toLowerCase();
      const schweregrad = SCHWEREGRAD_MAP[schwerегradRaw] || "mittel";
      const fotoUrl = item.Photo?.url || null;
      const fotoUrl2 = item.Photo_2?.url || null;
      const frist = item.Photos_DateTime || null;
      const zustaendigEmail = item.SelectData?.Email || null;
      const zustaendigName = item.SelectData?.Name || null;

      return {
        beschreibung,
        kategorie: "sonstiges",
        schweregrad,
        fotoUrl,
        fotoUrl2,
        ortNotiz,
        frist,
        zustaendigEmail,
        zustaendigName,
      };
    })
    .filter((m) => m !== null);
}

function mapBegehungTyp(selectValue) {
  if (!selectValue) return "Standardbegehung";
  const key = selectValue.toLowerCase().trim();
  return BEGEHUNG_TYP_MAP[key] || "Standardbegehung";
}

function parseDatum(dateStr) {
  if (!dateStr) return new Date();
  const parsed = new Date(dateStr);
  return isNaN(parsed.getTime()) ? new Date() : parsed;
}

// ==========================================================
// Mangel-Erinnerung — Täglich um 8 Uhr
// ==========================================================
exports.mangelErinnerung = onSchedule(
  {
    schedule: "0 8 * * *",
    timeZone: "Europe/Berlin",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();
    const morgen = new Date();
    morgen.setDate(morgen.getDate() + 1);

    const snap = await db
      .collectionGroup("maengel")
      .where("status", "in", ["offen", "in_bearbeitung"])
      .where("frist", "<=", admin.firestore.Timestamp.fromDate(morgen))
      .where("erinnerung_gesendet", "==", false)
      .get();

    console.log(
      `📧 ${snap.docs.length} Mängel mit ablaufender Frist gefunden.`
    );

    for (const doc of snap.docs) {
      const mangel = doc.data();

      await db.collection("mail").add({
        to: mangel.zustaendig_email || "",
        message: {
          subject: `Mangel-Frist läuft ab: ${(mangel.beschreibung || "").substring(0, 50)}`,
          html: `<p>Hallo ${mangel.zustaendig_name || ""},</p>
                 <p>der folgende Mangel muss bis <strong>${mangel.frist.toDate().toLocaleDateString("de-DE")}</strong> behoben sein:</p>
                 <p><strong>${mangel.beschreibung}</strong></p>
                 <p>Schweregrad: ${mangel.schweregrad}</p>
                 <p>Bitte melden Sie sich in der SGEW App um den Status zu aktualisieren.</p>`,
        },
      });

      await doc.ref.update({ erinnerung_gesendet: true });
    }
  }
);

// ==========================================================
// Jahreswechsel — Counter zurücksetzen am 1. Januar
// ==========================================================
exports.jahreswechsel = onSchedule(
  {
    schedule: "0 0 1 1 *",
    timeZone: "Europe/Berlin",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();

    const usersSnap = await db.collection("users").get();
    const batch1 = db.batch();
    for (const doc of usersSnap.docs) {
      batch1.update(doc.ref, { begehungenDiesesJahr: 0 });
    }
    await batch1.commit();

    const abtSnap = await db.collection("abteilungen").get();
    const batch2 = db.batch();
    for (const doc of abtSnap.docs) {
      batch2.update(doc.ref, { begehungenDiesesJahr: 0 });
    }
    await batch2.commit();

    console.log("🎆 Jahreswechsel: Counter zurückgesetzt");
  }
);