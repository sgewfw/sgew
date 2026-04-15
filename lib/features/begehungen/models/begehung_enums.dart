enum BegehungTyp {
  standardbegehung,
  baustellenbegehung,
  sicherheitsbegehung,
  fremdfirmenbegehung;

  String get label {
    switch (this) {
      case BegehungTyp.standardbegehung:
        return 'Standardbegehung';
      case BegehungTyp.baustellenbegehung:
        return 'Baustellenbegehung';
      case BegehungTyp.sicherheitsbegehung:
        return 'Sicherheitsbegehung';
      case BegehungTyp.fremdfirmenbegehung:
        return 'Fremdfirmenbegehung';
    }
  }

  static BegehungTyp fromString(String value) {
    return BegehungTyp.values.firstWhere(
          (e) => e.label.toLowerCase() == value.toLowerCase() || e.name == value,
      orElse: () => BegehungTyp.standardbegehung,
    );
  }
}

enum BegehungStatus {
  offen,
  abgeschlossen,
  archiviert;

  String get label {
    switch (this) {
      case BegehungStatus.offen:
        return 'Offen';
      case BegehungStatus.abgeschlossen:
        return 'Abgeschlossen';
      case BegehungStatus.archiviert:
        return 'Archiviert';
    }
  }

  String get firestoreValue {
    switch (this) {
      case BegehungStatus.offen:
        return 'offen';
      case BegehungStatus.abgeschlossen:
        return 'abgeschlossen';
      case BegehungStatus.archiviert:
        return 'archiviert';
    }
  }

  static BegehungStatus fromString(String? value) {
    if (value == null) return BegehungStatus.offen;
    return BegehungStatus.values.firstWhere(
          (e) => e.firestoreValue == value || e.name == value,
      orElse: () => BegehungStatus.offen,
    );
  }
}

enum MangelKategorie {
  absturz,
  elektro,
  brand,
  chemikalien,
  ordnungSauberkeit,
  persoenlicheSchutzausruestung,
  maschinen,
  verkehr,
  sonstiges;

  String get label {
    switch (this) {
      case MangelKategorie.absturz:
        return 'Absturz';
      case MangelKategorie.elektro:
        return 'Elektro';
      case MangelKategorie.brand:
        return 'Brand';
      case MangelKategorie.chemikalien:
        return 'Chemikalien';
      case MangelKategorie.ordnungSauberkeit:
        return 'Ordnung & Sauberkeit';
      case MangelKategorie.persoenlicheSchutzausruestung:
        return 'Persönliche Schutzausrüstung';
      case MangelKategorie.maschinen:
        return 'Maschinen';
      case MangelKategorie.verkehr:
        return 'Verkehr';
      case MangelKategorie.sonstiges:
        return 'Sonstiges';
    }
  }

  static MangelKategorie fromString(String value) {
    return MangelKategorie.values.firstWhere(
          (e) => e.label.toLowerCase() == value.toLowerCase() || e.name == value,
      orElse: () => MangelKategorie.sonstiges,
    );
  }
}

enum MangelSchweregrad {
  kritisch,
  mittel,
  gering;

  String get label {
    switch (this) {
      case MangelSchweregrad.kritisch:
        return 'Kritisch';
      case MangelSchweregrad.mittel:
        return 'Mittel';
      case MangelSchweregrad.gering:
        return 'Gering';
    }
  }

  static MangelSchweregrad fromString(String value) {
    return MangelSchweregrad.values.firstWhere(
          (e) => e.label.toLowerCase() == value.toLowerCase() || e.name == value,
      orElse: () => MangelSchweregrad.mittel,
    );
  }
}

enum MangelStatus {
  offen,
  inBearbeitung,
  behoben;

  String get label {
    switch (this) {
      case MangelStatus.offen:
        return 'Offen';
      case MangelStatus.inBearbeitung:
        return 'In Bearbeitung';
      case MangelStatus.behoben:
        return 'Behoben';
    }
  }

  String get firestoreValue {
    switch (this) {
      case MangelStatus.offen:
        return 'offen';
      case MangelStatus.inBearbeitung:
        return 'in_bearbeitung';
      case MangelStatus.behoben:
        return 'behoben';
    }
  }

  static MangelStatus fromString(String value) {
    return MangelStatus.values.firstWhere(
          (e) => e.firestoreValue == value || e.name == value,
      orElse: () => MangelStatus.offen,
    );
  }
}

enum UserRolle {
  mitarbeiter,
  be4,
  be3,
  be2,
  admin;

  String get label {
    switch (this) {
      case UserRolle.mitarbeiter:
        return 'Mitarbeiter';
      case UserRolle.be4:
        return 'BE4';
      case UserRolle.be3:
        return 'BE3';
      case UserRolle.be2:
        return 'BE2';
      case UserRolle.admin:
        return 'Admin';
    }
  }

  bool get istFuehrungskraft =>
      this == UserRolle.be4 ||
          this == UserRolle.be3 ||
          this == UserRolle.be2 ||
          this == UserRolle.admin;

  bool get kannInternesDashboardSehen => istFuehrungskraft;

  bool get kannAlleAbteilungenSehen =>
      this == UserRolle.be2 || this == UserRolle.admin;

  bool get kannUserVerwalten => this == UserRolle.admin;

  static UserRolle fromString(String value) {
    return UserRolle.values.firstWhere(
          (e) => e.label == value || e.name == value,
      orElse: () => UserRolle.mitarbeiter,
    );
  }
}

enum UserStatus {
  aktiv,
  ausstehend,
  gesperrt,
  abgelehnt;

  String get label {
    switch (this) {
      case UserStatus.aktiv:
        return 'Aktiv';
      case UserStatus.ausstehend:
        return 'Ausstehend';
      case UserStatus.gesperrt:
        return 'Gesperrt';
      case UserStatus.abgelehnt:
        return 'Abgelehnt';
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserStatus.aktiv:
        return 'aktiv';
      case UserStatus.ausstehend:
        return 'ausstehend';
      case UserStatus.gesperrt:
        return 'gesperrt';
      case UserStatus.abgelehnt:
        return 'abgelehnt';
    }
  }

  bool get istAktiv => this == UserStatus.aktiv;

  static UserStatus fromString(String? value) {
    if (value == null) return UserStatus.aktiv;
    return UserStatus.values.firstWhere(
          (e) => e.firestoreValue == value || e.name == value,
      orElse: () => UserStatus.aktiv,
    );
  }
}

const Map<MangelSchweregrad, int> standardFristen = {
  MangelSchweregrad.kritisch: 1,
  MangelSchweregrad.mittel: 7,
  MangelSchweregrad.gering: 30,
};