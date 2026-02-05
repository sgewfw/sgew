'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "8439beb8b1732c0a2985d22d90c57484",
".git/config": "920a11de313bfb8d93d81f4a3a5b71b6",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "6d637d4e8eabfc4b32263048bce5de1a",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "c2e531a0bd76e2f223af6f8e8ea2aab0",
".git/logs/refs/heads/gh-pages": "0f8a8cce64e174d31a411c6e1541d12e",
".git/objects/27/95805bb0040d2239fa358a0c01327d7454ab13": "9cf7e1ec668b653431f17b124aef7799",
".git/objects/28/bf09bce2bfa513bec5317fc943bd46098e9bdf": "288dea08f9ecb4dbfb81100bf97e7944",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/55/48f76ca4cb8778b2eef2a2921654739c88a218": "2d3a0f0bc4408573862aad9db03d882b",
".git/objects/5c/4ae47f0c2e23c7ebb558ce04c49a65b9b1bfbc": "6f6ac9270fa5f27ab90998c86e7d0553",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/72/64269fa51dc947bf8eb19f717f3ebaa95f20fa": "45a51d0ffea9859726c96f2b9adda828",
".git/objects/75/12d1107483ec8b3c3e871fb1a2b8519d1f87ce": "9498a4f744fce5cbf9cb135c51cc7dfd",
".git/objects/75/7b9ed6cf53d56613a2575b85314053dc4db455": "66ea37534fa1aab35d35f03c0273d392",
".git/objects/79/2613a9acae5ad2a821d4d7322cf710bca79969": "a057e70d9bf559268e61c2324ddcb78d",
".git/objects/7a/4b67536959c804354816e760b3b0811b810fa8": "cb33af9b71c7b64ef3fbdb1b51aa24c6",
".git/objects/7e/dd05a1a07d07a7bf6f67f8eb69271139a57fa3": "ffd5f6d276aece9b0a6d6a3a0716ed65",
".git/objects/7f/1e96fc448e4d0f7691b98847f4d48a4ea93858": "f24e62d50586ac78475801921a5de9af",
".git/objects/84/b5ef958780593d2d38070a530714d6b69445ca": "d948e77bdbb8c88e96f9c660333211e1",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8b/b74c85ca7045db25f11528667927dbc71c8526": "0d9031a85c7304511be0cf6ab87c427d",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/99/4b8b022c81c212cbc56545426cd435d911abc9": "8c97fda59c9279f53af99a94c7a3ce31",
".git/objects/a0/0e3fe0b38e5fd67ed634b89c9cf50ae7fe587b": "6854381a2a0fc6c62611d71189e45bd3",
".git/objects/a5/d07d5eeb04da01d772abe19e9997e3244c91b0": "2dd33da21902701b494fee3eb57508be",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/b1/73e99742bd53b166d83b5944440e0af134c4f0": "8dfa049d6ea820169c849d00c3895ee1",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bf/610d99cabfa2837cb7e63328827824278e03e6": "eef4517aa817340b806975aabc3cf818",
".git/objects/c1/d53243531ed44caf53a59f973dd950480b3f3c": "313d73b882dd474596d4a25c91d1bd0c",
".git/objects/c2/d5a522ec5dc28802e8f90d8410aa690e1e3d11": "2d24bca2541dab6db88fcd13c74e6014",
".git/objects/d1/0f02314da0f2735d877356cef94599556e1243": "501dfa7dc11e82a6c6d677838ec8a900",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/9b0fd58afab853d4ef3052b4daae6de262d9c1": "1b61ebf8649efcd0993b35e6ed279e07",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d7/9d90b3049c5aa3fa23bf52719298738ec444b4": "973cf50ecf6327ff5f3bbb5bc6d8ea30",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/e8/86ab8c31beccc7bbb860159ff32247de605210": "372f53a5d1f8fd6d8b878e448aed3dbe",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ee/c255d68032d48c07684d842eea4efc366d4983": "f7ce3ba912bce12d636a1132866d3430",
".git/objects/f0/6323930697df2d2153327366807b6717be1b62": "64bf127b3d33eae905a9810c0d3470c3",
".git/objects/f3/265b7086e8da1ba5344bccdc8f01f506919236": "78ac43fb9004bad1918478273bb931ee",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f5/770ec1c6490d8a2a242ad639a4aae12a305620": "59409887af4be77d60fe0819e3d89f8f",
".git/objects/f9/5d76b1095d1179bbda50437e8cc9148c2cb086": "ec7454262c8875e86a6e5b607471f2cd",
".git/refs/heads/gh-pages": "ed06143169e02cab5a7b191e3102d025",
"assets/AssetManifest.bin": "438ec69ae5258692b0fbc7993f79da3e",
"assets/AssetManifest.bin.json": "7b1cc9b68cece980ea88d7ac0ef2e409",
"assets/assets/images/logo.png": "676fdbd3e4db5114001157b11bdc46ce",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "0ce34171553285c19e5182e01dd150c6",
"assets/NOTICES": "64be40dcb5383fae99945c07dcfa66d7",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "e7bdab2993e1dfb8299b368486fefede",
"canvaskit/canvaskit.wasm": "d8d7d4dd48a0508729be5f2e09da17c9",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "fd49f28f2bf9b8efabb6b429231732cb",
"canvaskit/chromium/canvaskit.wasm": "ec0f6ca33dffc426a38afc70ec73cb42",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "9bb7ab7bc3ae6a0dbd502ecfa670c50b",
"canvaskit/skwasm.wasm": "716df9ce9fbae17232d3bdd5820fe689",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "5b202265a20e326159a97e8ba1cd184e",
"canvaskit/skwasm_heavy.wasm": "6e70ff0d20781c7feea29975cc2cff94",
"favicon.png": "1e24468f09944f6950fafd1ff544694b",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "5c28a454cb72834952b88db772993150",
"icons/Icon-192.png": "829a18893bfbf9442e58a7aa08bc23f3",
"icons/Icon-512.png": "b2cdd7736f4b1c1fb593c39f0f9743d6",
"icons/Icon-maskable-192.png": "829a18893bfbf9442e58a7aa08bc23f3",
"icons/Icon-maskable-512.png": "b2cdd7736f4b1c1fb593c39f0f9743d6",
"index.html": "69e7047b07555e45dcc7b1bee5a4d57e",
"/": "69e7047b07555e45dcc7b1bee5a4d57e",
"main.dart.js": "dd547781ec31446920e761047a6d2c81",
"manifest.json": "08218a418cfdb0c20e79b117218b74dc",
"version.json": "3be2b992f6fea64c9c5d093b18787dd2"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
