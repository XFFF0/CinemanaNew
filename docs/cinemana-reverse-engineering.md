# Cinemana APK v5.3.3 — Complete Reverse Engineering Report

**Package:** `com.shabakaty.cinemana`
**APK:** `cinemana-5-3-3.apk`
**Tools:** jadx (decompiler), apktool (resource decoding), grep/rg (pattern search)
**Obfuscation:** ProGuard/R5 (full class/method name obfuscation in `com.shabakaty.downloader.*`)

---

## 1. UI / Screen Structure

### 1.1 Activity Inventory (from AndroidManifest.xml)

| Activity | Class | Purpose |
|---|---|---|
| **SplashActivity** | `com.shabakaty.cinemana.ui.splash.SplashActivity` | Splash screen, IP detection, deep link handling, auto-navigate to Home |
| **HomeActivity** | `com.shabakaty.cinemana.ui.home_activity.HomeActivity` | Main container with bottom navigation (tabs) |
| **StatusActivity** | `com.shabakaty.cinemana.ui.status.StatusActivity` | Server status page |
| **DownloadsActivity** | `com.shabakaty.cinemana.ui.downloads.DownloadsActivity` | Download manager UI |
| **VideoPlayerActivity** | `com.shabakaty.cinemana.player.VideoPlayerActivity` | Full-screen video player |
| **SettingsActivity** | `com.shabakaty.cinemana.ui.settings.SettingsActivity` | App settings |
| **LoginActivity** | `com.shabakaty.cinemana.ui.login.LoginActivity` | Email/password login |
| **SignUpActivity** | `com.shabakaty.cinemana.ui.login.SignUpActivity` | Registration |
| **QrLoginActivity** | `com.shabakaty.cinemana.ui.qr_login.QrLoginActivity` | QR code login |
| **QrScanningActivity** | `com.shabakaty.cinemana.ui.qr_login.QrScanningActivity` | QR code scanner |
| **ExpandedControlsActivity** | `.helpers.casting.ExpandedControlsActivity` | Chromecast expanded controls |
| **DLNAControlsActivity** | `.helpers.casting.DLNAControlsActivity` | DLNA remote control |

### 1.2 Fragment-Based Navigation

HomeActivity uses a single `FragmentContainerView` with a **Navigation Component** (`NavHostFragment`). The bottom navigation (`BottomNavigationView`) has navigation graph destinations including:

- **HomeFragment** (`vt1` — obfuscated) — main feed
- **BrowseFragment** — categories/collections
- **SearchFragment** — search
- **ProfileFragment** — user profile
- **ShowMorePageFragment** — paginated video grid from any group

### 1.3 Navigation Flow

```
SplashActivity
  ├── IP detection (https://share.shabakaty.com/whatismyip + ipify fallback)
  ├── Deep link parsing (/video/{id}, /page/movie/watch/en/, /page/home)
  └── → HomeActivity

HomeActivity (4-tab BottomNavigationView)
  ├── Tab 1: Home (fragments: banners, groups, newly added)
  ├── Tab 2: Browse (categories list, collections list)
  ├── Tab 3: Search (advanced search with filters)
  └── Tab 4: Profile (user info, history, subs, notifs, settings)

VideoDetail
  ├── VideoPlayerActivity (full-screen ExoPlayer)
  ├── ExpandedControlsActivity (Cast)
  └── DLNAControlsActivity (DLNA)

LoginActivity → SignUpActivity
SettingsActivity
DownloadsActivity
StatusActivity
```

### 1.4 UI Components (per Screen)

**Home Screen:** Vertical ScrollView → [BannerCarousel] + [VideoRow: "Newly Added"] + [VideoRow per VideoGroup]
**Browse:** List/RecyclerView sections → Categories + Collections
**Search:** Query field + Filter chips (type/year/category) + Paginated Grid (LazyVGrid equiv)
**Video Detail:** Banner image + Title/Meta + Like/Sub buttons + Episodes carousel + TranscodedFiles qualities + Comments List + Recommendations
**Player:** Custom CinemanaPlayerView (FrameLayout wrapper) + Custom Controller overlay + SubtitleView (ExoPlayer)

---

## 2. Networking Layer Implementation

### 2.1 HTTP Client: OkHttp (via Retrofit)

The decompiled code reveals a custom wrapped Retrofit/OkHttp setup. Key files in `com.shabakaty.downloader`:

**Base URL configuration (from `px4.java` + `s30.java`):**
- Main API: `https://cinemana.shabakaty.com/api/android/`
- Analytics: `https://cinemana.shabakaty.com`
- Account: `https://account.shabakaty.com/`
- CDN: `https://cnth2.shabakaty.com/`
- Recommendations: `https://recommend.shabakaty.com/api/recommendation/recommend/`
- Status Page: `https://6b1m6vnfz2jk.statuspage.io/api/v2/components.json`
- IP: `https://share.shabakaty.com/whatismyip` / `https://api.ipify.org/?format=json`

**OkHttp Client Setup (from `a63.a` builder pattern):**
```java
// Decompiled from px4.java line ~75-92
a63.a aVar = new a63.a();
aVar.b(15L, TimeUnit.SECONDS);       // connectTimeout
aVar.d(15L, TimeUnit.SECONDS);       // readTimeout
aVar.e(15L, TimeUnit.SECONDS);       // writeTimeout
aVar.k = cache;                       // Cache (10MB, in app cache dir)
aVar.g = new UserAuthenticator(userManagement);  // Auth interceptor
aVar.a(authInterceptor);              // Authorization interceptor
aVar.a(new wp());                     // User-agent interceptor
aVar.d.add(new aq());                 // Other interceptor
```

**Interceptors:**
1. `jf` (AuthorizationInterceptor) — injects Bearer token from UserManagement
2. `wp` (UserAgentInterceptor) — sets User-Agent header
3. `aq` — additional header interceptor
4. `UserAuthenticator` — implements OAuth token refresh on 401 responses

**Retrofit Builder (from `lt3.b`):**
```java
lt3.b bVar = new lt3.b();
bVar.d.add(new nr1(new lr1()));  // Gson converter
bVar.e.add(wv3.b());              // RxJava adapter (Flowable/io.reactivex)
bVar.c(okHttpClient);
bVar.a("https://cinemana.shabakaty.com/api/android/");
```

### 2.2 API Service Interface Pattern

The original Kotlin files (`ApiServices.kt`, `AnalyticsApiManagerPlayer.kt`, etc.) use **custom Retrofit annotations** (ProGuard-obfuscated names):

| Obfuscated | Actual Retrofit | Usage |
|---|---|---|
| `@i93` | `@POST` | HTTP POST |
| `@lo1` | `@GET` | HTTP GET |
| `@j93` | `@PATCH` | HTTP PATCH |
| `@vh1` | `@FormUrlEncoded` | Form URL encoding |
| `@rv2` | `@Multipart` | Multipart request |
| `@la1` | `@Field` | Form field |
| `@va3` | `@Path` | URL path param |
| `@ok3` | `@Query` | URL query param |
| `@os1` | `@Header` | HTTP header |
| `@sm` | `@Body` | Request body (JSON) |
| `@sa3` | `@Part` | Multipart part |

### 2.3 Response Wrapper

API responses use a generic wrapper pattern:
```java
// xs3<T> — wrapped response with status code + data
// From q5.java: f74<xs3<ys3>>
public class xs3<T> {
    public int v;        // HTTP status code
    public T a;          // Response data
    public String b;     // Error message
}
```

Observables consistently use RxJava types:
- `f74<T>` → wraps `io.reactivex.Observable<T>`
- `t43<T>` → wraps `io.reactivex.Single<T>`
- `qf1<T>` → wraps `java.util.concurrent.Flowable<T>`
- `ud0<? super T>` → wraps `kotlin.coroutines.Continuation<T>` (suspend functions)
- `@wh1` → `kotlin.coroutines.jvm.internal` (suspend marker)
- `tm1<T,R>` → `kotlin.jvm.functions.Function1<T,R>`

The response is always wrapped via `xs3`, and clients check `xs3.v == 200` before using `xs3.a`.

---

## 3. Authentication Flow

### 3.1 OAuth2 Token Flow

**Discovery from `s30.java`:**
```java
new UserManagementConfiguration(
    "https://account.shabakaty.com/",
    new ClientInformation(
        "com.shabakaty",              // clientId
        "Shabakaty.Mobile",           // appName
        "secret",                     // clientSecret
        "openid email offline_access earthlink.profile fileservice songster",  // scope
        "cTnj9bUcDmr08B586K7pGFHy",  // appSecret (OAuth secret)
        "809377071843-jc87v0q9i2f0k20sncd3rordaj79e1ul.apps.googleusercontent.com" // Google client ID
    ),
    true,    // isDebug
    null     // deviceFlowClientInformation
)
```

**Token Request (password grant):**
```
POST https://account.shabakaty.com/core/connect/token
Authorization: Basic U2hhYmFrYXR5Lk1vYmlsZTpzZWNyZXQ=
Content-Type: application/x-www-form-urlencoded

username={email}&password={password}&scope=openid+email+offline_access+earthlink.profile+fileservice+songster&grant_type=password
```

The `Basic` auth header decodes to: `Shabakaty.Mobile:secret`

**Token Response:**
```json
{
    "access_token": "...",
    "refresh_token": "...",
    "expires_in": 3600,
    "token_type": "Bearer",
    "scope": "openid email offline_access earthlink.profile fileservice songster"
}
```

**Token Refresh:**
```
POST https://account.shabakaty.com/core/connect/token
Authorization: Basic U2hhYmFrYXR5Lk1vYmlsZTpzZWNyZXQ=
Content-Type: application/x-www-form-urlencoded

refresh_token={refreshToken}&scope=openid+email+offline_access+earthlink.profile+fileservice+songster&grant_type=refresh_token
```

**Device Login:**
```
GET https://account.shabakaty.com/core/api/device?userCode={code}
Authorization: Bearer {token}
```

### 3.2 Token Storage

Tokens are stored in **Android SharedPreferences** (file name: `once`), **NOT Keychain/EncryptedSharedPreferences**:

```java
// Decompiled from CinemanaApplication.java line ~511
SharedPreferences sharedPreferences = getApplicationContext().getSharedPreferences("once", 0);
```

The UserManagement library uses SharedPreferences for storing:
- `access_token` 
- `refresh_token`
- User ID (via `UserManagement.getUserId()`)

The local library `com.shabakaty.usermanagement` wraps this with its own session management class `ff3` (obfuscated). No hardware-backed encryption is used for the token store.

### 3.3 Facebook/Google Login

**Facebook:**
- App ID: `1870041376359385`
- Login scheme: `fb1870041376359385`
- Endpoint: `GET https://account.shabakaty.com/core/connect/facebook?token={fbToken}&clientId={id}&scope=...`

**Google:**
- Client ID: `809377071843-jc87v0q9i2f0k20sncd3rordaj79e1ul.apps.googleusercontent.com`
- Endpoint: `GET https://account.shabakaty.com/core/connect/google?token={googleToken}&clientId={id}&scope=...`

### 3.4 Device Registration (From SplashActivity analysis)

```java
// SplashActivity.onCreate() decompiled logic:
gy2 networkInfo = this.w;
networkInfo.b(false);    // Check IP via share.shabakaty.com/whatismyip 
networkInfo.b(true);     // Fallback: api.ipify.org/?format=json

// Device ID generation (from q5.java constructor):
String deviceId = Build.MANUFACTURER + '_' + Build.MODEL;
// Random user identifier stored in SharedPreferences:
long userId = new Random().nextLong() >>> 1;

// Device login called from AuthActivity:
POST /api/android/login/  (FormUrlEncoded)
Fields: deviceId, deviceName, playerId
```

The `playerId` parameter is the **OneSignal player ID** (push notification token).

---

## 4. Data Models

### 4.1 Local VideoModel (full decompiled field list)

From `com.shabakaty.cinemana.domain.models.local.VideoModel` (implements `Parcelable`):

```java
public final class VideoModel implements Parcelable {
    public String nb;                 // Video ID (primary key)
    public String title;              // Computed title (c() method: picks arTitle/enTitle)
    public String enTitle;            // English title
    public String arTitle;            // Arabic title
    public String stars;              // Cast/starring
    public String arContent;          // Arabic description
    public String enContent;          // English description
    public String mDate;              // Release date
    public String year;               // Year
    public String kind;               // Content type (movie/series)
    public String season;             // Season number
    public String imgObjUrl;          // Main image URL
    public String imgMediumThumbObjUrl; // Medium thumbnail
    public String imgThumbObjUrl;     // Thumbnail
    public String filmRating;         // Movie rating
    public String seriesRating;       // Series rating
    public String episodeNummer;      // Episode number
    public String episodeFlag;        // Episode flag
    public String rate;               // User rating
    public String isSpecial;          // Special flag
    public String itemDate;           // Item date
    public String duration;           // Duration
    public String imdbUrlRef;         // IMDB URL
    public String rootSeries;         // Root series ID
    public String useParentImg;       // Use parent image
    public boolean showComments;      // Show comments
    public String trailer;            // Trailer URL
    public boolean isMock;            // Mock flag
    public String parentSkipping;     // Parental skipping
    public int downloadCollectionID;  // Collection ID for download
    public SkippingDurations skippingDurations; // Opening/ending skip times
    public String arTranslationFilePath; // Arabic translation file
    public List<Subtitle> subtitles;  // Subtitle list
    public boolean hasIntroSkipping;  // Has intro skip
    public List<o84> skippableScenes; // Skippable scene timestamps
    public List<Category> categories; // Categories
    public String videoLikesNumber;   // Like count
    public String videoDisLikesNumber;// Dislike count
    public VideoLanguages videoLanguages; // Available languages
    public int videoCommentsNumber;   // Comment count
    public String videoViewsNumber;   // View count
    public List<ob4> directorsInfo;   // Directors
    public List<ob4> actorsInfo;      // Actors  
    public List<ob4> writersInfo;     // Writers
    public String itemOrderList;      // Display order
    public String listId;             // List ID
    public String listSortOrder;      // Sort order
    public String castable;           // Castability flag
    public String publishDate;        // Publish date
    public String episodeDesc;        // Episode description
    public String customArTitle;      // Custom Arabic title
    public String customEnTitle;      // Custom English title
    public boolean finished;          // Finished watching
    public String url;                // Video URL
    public int downloadTaskId;        // Download task ID
    public long downloadedTime;       // Download timestamp
    public String size;               // Size
    public String description;        // Description
    public boolean isAddedToWatchLater; // Watch later
    public q25 status;                // Status enum
    public List<Quality> qualities;   // Available qualities
    public Quality wantedQuality;     // Selected quality
    public String arTranslationFilePathVTT; // VTT translation
    public boolean isDownloading;     // Downloading state
}
```

### 4.2 Supporting Local Models

```java
// Quality
public class Quality implements Parcelable {
    public String resolution;  // e.g., "720p", "1080p"
    public String name;        // Quality name
    public String url;         // File path or URL
}

// SkippingDurations
public class SkippingDurations implements Parcelable {
    public List<String> start; // Skip start timestamps
    public List<String> end;   // Skip end timestamps
}

// Subtitle
public class Subtitle implements Parcelable {
    public String id;
    public String name;
    public String type;        // Language code
    public String extension;   // srt, vtt
    public String file;        // File path or URL
}

// TranscodeFile (from domain.models.local)
public class TranscodeFile {
    public String url;
    public String quality;
    public long size;
}

// VideoLanguages
public class VideoLanguages {
    public List<String> audio;   // Audio languages
    public List<String> subtitle; // Subtitle languages
}
```

### 4.3 Database Schema (Room Database)

From `com.shabakaty.cinemana.data.db.AppDatabase` — Room database with 5 DAOs:

```java
public abstract class AppDatabase extends vt3 { // RoomDatabase
    public abstract jw0 p();     // DAO for CinemanaDownloadItem
    public abstract vy3 q();     // DAO for SearchItem
    public abstract u24 r();     // DAO for SettingsEntity
    public abstract g25 s();     // DAO for VideoStatusEntity
    public abstract s25 t();     // DAO for SubtitleDb
}
```

**Tables:**

1. **downloads** (CinemanaDownloadItem): 23 fields, Parcelable, used for download queue persistence
2. **search_history** (SearchItem): stores recent search queries
3. **settings** (SettingsEntity): userId + filterSettings (FilterSettingsEntity) + appSettings (AppSettingsEntity) + subtitlesSettings (pg4)
4. **video_status** (VideoStatusEntity): watch progress per video (position, finished status)
5. **subtitles** (SubtitleDb): downloaded subtitle file metadata

Key Download Item fields:
```java
public class CinemanaDownloadItem implements Parcelable {
    public String id; public int downloadTaskId; public String title;
    public String stars; public String kind; public int sizeMB;
    public String season; public String imgObjUrl;
    public String filmRating; public String tvShowRating;
    public String path; public String episodeNumber;
    public String special; public String useParentImg;
    public String parentSkipping; public int collectionID;
    public String imgThumbObjUrl;
    public SkippingDurationsDB skippingDurations;
    public String qualityName; public String rootEpisode;
    public boolean hasIntroSkipping; public String episodeFlag;
    public String lastUpdated;
}
```

### 4.4 SharedPreferences Key Inventory

Keys found across the codebase (all stored in default SharedPreferences):

| Key | Type | Purpose |
|---|---|---|
| `user_id_login` | String | Logged-in user ID |
| `user_identifier` | String/Long | Device-level random user ID |
| `key_sent_user_info` | Boolean | Whether user info has been sent |
| `parental_level` | String | Current parental level |
| `app_language` | String | App language (ar/en/ku) |
| `key_service_is_down` | Boolean | Server maintenance flag |
| `playerAnalyticsTime` | Long | Last analytics send timestamp |
| `key_auto_play_next_episode` | Boolean | Auto-play next episode setting |
| `key_preferred_subtitle_language` | String | Preferred subtitle language |
| `qualityName` | String | Last selected quality name |
| `qualityUrl` | String | Last selected quality URL |
| `qualityResolution` | String | Last selected quality resolution |

---

## 5. Video Player Logic

### 5.1 Player Library: ExoPlayer (AndroidX Media3)

The app uses **Google ExoPlayer** (`com.google.android.exoplayer2`). Evidence:

- `CinemanaPlayerView.java` extends `FrameLayout` and wraps ExoPlayer
- `SubtitleView` imported from `com.google.android.exoplayer2.ui.SubtitleView`
- The `s64` type (obfuscated) is the ExoPlayer `Player` interface
- AD types referenced: `ad3` = `AspectRatioFrameLayout`

**Player class hierarchy:**
```
VideoPlayerActivity (extends xi<d4, p10, q10>)
  └── contains: CinemanaPlayerView (extends FrameLayout)
        └── contains: ExoPlayer (s64), SubtitleView, SurfaceView
        └── contains: CinemanaPlayerControllerView (overlay controls)
```

### 5.2 Stream Resolution Flow

1. `getTranscodedFiles(id/{videoNb})` returns `[TranscodedFile]`
2. Each file has `url`, `quality` (e.g., "720p", "1080p"), `size`
3. The best quality is auto-selected by sorting by size descending
4. User can switch quality through the controller settings bottom sheet
5. On quality change: current position saved → new URL loaded → seek to position

**Code flow (from CinemanaPlayerView + CinemanaPlayerControllerView):**
```java
// Quality selection triggers player reload
// From a.java (CinemanaPlayerControllerView.onQualitySelected):
public Object o(se0 se0Var, ud0<? super qv4> ud0Var) {
    this.v.getCinemanaPlayerView().y(); // y() = play/resume
    return qv4.a;
}

// Quality persisted to SharedPreferences:
ff3Var.b.putString("qualityName", quality.name)
      .putString("qualityUrl", quality.url)
      .putString("qualityResolution", quality.resolution)
      .apply();
```

### 5.3 DRM & URL Security

The analysis found **no DRM implementation**. The stream URLs from `transcoddedFiles/id/{videoNb}` appear to be direct HTTP URLs. However, some endpoints use `Cache-Control: cacheable-for-authorized` headers, suggesting cookie/token-based access control on the CDN but not DRM encryption (no Widevine/PlayReady references).

### 5.4 Skipping/Intro Detection

The app supports content skipping (intro/recap):
```java
SkippingDurations skippingDurations = videoModel.skippingDurations;
ja3VarC.c(skippingDurations.start, skippingDurations.end);
// start = ["0", "180"]  end = ["90", "210"]  (seconds as strings)
```

Skippable scenes (`List<o84>`) are also used for ad/mature content skip.

### 5.5 Casting / DLNA

Two casting methods:
1. **Google Cast** (Chromecast): via `com.google.android.gms.cast.framework`, `CastOptionsProvider`
2. **DLNA**: via `ConnectSDK` (`com.connectsdk`), custom `DLNAControllerService`

The `DLNAControlsActivity` acts as a remote control for DLNA playback on smart TVs.

---

## 6. Build / Project Configuration

### 6.1 Permissions (full list from Manifest)

```
INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE
READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
CAMERA (QR scanning)
VIBRATE, WAKE_LOCK, FOREGROUND_SERVICE
READ_PHONE_STATE
REQUEST_INSTALL_PACKAGES
RECEIVE_BOOT_COMPLETED
MANAGE_EXTERNAL_STORAGE
GET_ACCOUNTS, AUTHENTICATE_ACCOUNTS, MANAGE_ACCOUNTS, READ_PROFILE, READ_CONTACTS
CHANGE_WIFI_MULTICAST_STATE
REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
C2D_MESSAGE (FCM/OneSignal)
Various badge notification permissions (Samsung, HTC, Sony, Huawei, Oppo, etc.)
```

### 6.2 Third-Party SDKs

| SDK | Package | Version | Purpose |
|---|---|---|---|
| **ExoPlayer** | `com.google.android.exoplayer2` | 2.x | Video playback |
| **Firebase Analytics** | `com.google.firebase.analytics` | - | Analytics |
| **Firebase Crashlytics** | `com.google.firebase.crashlytics` | - | Crash reporting |
| **Firebase Performance** | `com.google.firebase.perf` | - | Performance monitoring |
| **Firebase Remote Config** | `com.google.firebase.remoteconfig` | - | Remote configuration |
| **Firebase Messaging (FCM)** | `com.google.firebase.messaging` | - | Push notifications |
| **OneSignal** | `com.onesignal` | 4.x | Push notifications (primary) |
| **Facebook SDK** | `com.facebook` | 9+ | Facebook Login, Fresco images |
| **Google Sign-In** | `com.google.android.gms.auth` | - | Google Login |
| **Google Cast** | `com.google.android.gms.cast` | - | Chromecast |
| **ConnectSDK** | `com.connectsdk` | 1.x | DLNA discovery & control |
| **Zendesk** | `zendesk.*` | 5.x | Customer support SDK |
| **AppUpdater** | `com.github.javiersantos:appupdater` | - | Update checker |
| **OkHttp** | `com.shabakaty.downloader` (wrapped) | 4.x | HTTP client |
| **Retrofit** | wrapped via custom annotations | 2.x | REST client |
| **RxJava 2** | `io.reactivex` | 2.x | Reactive streams |
| **Room** | `androidx.room` | 2.x | SQLite ORM |
| **Fresco** | `com.facebook.drawee` | 2.x | Image loading |
| **Liulishuo FileDownloader** | `com.liulishuo.filedownloader` | 1.x | Download manager |
| **CameraX** | `androidx.camera` | 1.x | QR scanning camera |
| **Google Play Services** | `com.google.android.gms` | - | Google services |
| **WorkManager** | `androidx.work` | 2.x | Background tasks |

### 6.3 Firebase Configuration

From `strings.xml`:
```xml
<string name="firebase_database_url">https://music-1539414046135.firebaseio.com</string>
<string name="gcm_defaultSenderId">809377071843</string>
<string name="google_api_key">AIzaSyCOSZGpLRJk1or-Sdb-jFUFDcxoLPHczUg</string>
<string name="google_app_id">1:809377071843:android:7f93cc28a3df5957</string>
<string name="google_storage_bucket">music-1539414046135.appspot.com</string>
<string name="default_web_client_id">809377071843-jc87v0q9i2f0k20sncd3rordaj79e1ul.apps.googleusercontent.com</string>
```

### 6.4 Crashlytics Build ID
```
<string name="com.crashlytics.android.build_id">70138755f87e4cc1af331a29fe391e3f</string>
```

### 6.5 ProGuard Obfuscation Mapping

The mapping was **not included** in the APK (no `mapping.txt`). Obfuscation was applied with:

**Package-level renaming:**
- `com.shabakaty.downloader.*` → Fully obfuscated (classes renamed to 2-4 character names like `k9`, `px4`, `q5`)
- `com.shabakaty.cinemana.*` → Partially preserved (only method bodies obfuscated, class names kept)

**Obfuscation patterns found:**
- Custom Retrofit annotations renamed: `@i93`=POST, `@lo1`=GET, `@j93`=PATCH, `@vh1`=FormUrlEncoded, `@rv2`=Multipart
- Field/method names shortened: `a()`, `b()`, `r()`, `s()`, `t()`
- String constants inlined or computed via `j32.j()` (string concatenation helper)
- Boolean/Integer flags packed into metadata annotations

**Type aliases (for rebuilding):**
| Obfuscated | Actual Type |
|---|---|
| `f74<T>` | `io.reactivex.Observable<T>` |
| `t43<T>` | `io.reactivex.Single<T>` |
| `qf1<T>` | `java.util.concurrent.Flowable<T>` |
| `ud0<T>` | `kotlin.coroutines.Continuation<T>` |
| `tm1<T,R>` | `kotlin.Function1<T,R>` |
| `rm1<T>` | `kotlin.Function0<T>` (supplier) |
| `xs3<T>` | API response wrapper (status + data) |
| `s64` | `com.google.android.exoplayer2.Player` |
| `a63` | `okhttp3.OkHttpClient` |
| `lt3` | `retrofit2.Retrofit` |
| `kf2` | `kotlin.Lazy` (lazy delegate) |
| `ff3` | SharedPreferences wrapper |
| `j32` | Kotlin `Intrinsics` (null checks) |
| `qv4` | `kotlin.Unit` |
| `vt3` | `androidx.room.RoomDatabase` |
| `xi<T1,T2,T3>` | `androidx.appcompat.app.AppCompatActivity` (MVVM base activity) |
| `i93` | `retrofit2.http.POST` |
| `lo1` | `retrofit2.http.GET` |
| `j93` | `retrofit2.http.PATCH` |
| `vh1` | `retrofit2.http.FormUrlEncoded` |
| `rv2` | `retrofit2.http.Multipart` |
| `la1` | `retrofit2.http.Field` |
| `va3` | `retrofit2.http.Path` |
| `ok3` | `retrofit2.http.Query` |
| `os1` | `retrofit2.http.Header` |
| `sm` | `retrofit2.http.Body` |
| `sa3` | `retrofit2.http.Part` |

### 6.6 Native Libraries

```
lib/arm64-v8a/
  libbarhopper_v2.so        (barcode/QR scanning — Google ML Kit)
  librsjni.so               (RenderScript)
  libRSSupport.so           (RenderScript)
  librsjni_androidx.so      (RenderScript AndroidX)
  libimagepipeline.so       (Fresco image pipeline native)
  libnative-imagetranscoder.so  (Fresco image transcoding)
  libnative-filters.so      (Fresco image filters)
```

All native code is from third-party libraries (Fresco, ML Kit Barcode Scanning, RenderScript) — no custom native code.

---

## 7. Key Implementation Details for iOS Rebuild

### 7.1 Critical Differences to Handle

1. **Reactive Architecture**: The Android app uses RxJava extensively. iOS can use `async/await` or Combine.
2. **Response Wrapping**: Every API response is wrapped in `xs3<T>` with a status code check. iOS must unwrap the same envelope.
3. **SharedPreferences vs Keychain**: Android stores tokens unencrypted. iOS should use Keychain for security.
4. **ExoPlayer → AVPlayer**: Map ExoPlayer API calls to AVPlayer equivalents. Custom controller UI needs rebuilding.
5. **Fresco → Kingfisher/Nuke/SDWebImage**: Image loading pipeline
6. **FileDownloader**: iOS has no direct equivalent; use `URLSessionDownloadTask`
7. **OneSignal**: Has iOS SDK, use same app ID for push
8. **Cast/DIAL/DLNA**: iOS has `AVRoutePickerView` for AirPlay; Google Cast SDK for iOS available; DLNA/ConnectSDK has iOS version
9. **QR Scanning**: Use `AVFoundation` QR scanner on iOS
10. **WorkManager**: Use `BGTaskScheduler` on iOS

### 7.2 OAuth2 Config for iOS

```swift
let clientId = "com.shabakaty"
let clientSecret = "secret" // "cTnj9bUcDmr08B586K7pGFHy"  
let appName = "Shabakaty.Mobile" 
let scope = "openid email offline_access earthlink.profile fileservice songster"
let basicAuth = "U2hhYmFrYXR5Lk1vYmlsZTpzZWNyZXQ=" // "Shabakaty.Mobile:secret" base64
let googleClientId = "809377071843-jc87v0q9i2f0k20sncd3rordaj79e1ul.apps.googleusercontent.com"
let facebookAppId = "1870041376359385"
```

### 7.3 Cache-Control Handling

The API uses a custom `Cache-Control` header value: `cacheable-for-authorized, max-age=300`
iOS URLSession must handle this in URL cache policy or implement custom caching.

### 7.4 Analytics Format

The analytics POST body is constructed as:
```swift
let body: [String: String] = [
    "deviceType": "\(device.model)/\(systemVersion)",
    "userID": userId,
    "identifier": deviceId,
    "platform_type": "ios",
    "analytics": jsonArrayOfEvents  // JSON string array
]
```
Sent to `POST https://cinemana.shabakaty.com/api/info/ShabakatyInfo` (FormUrlEncoded).
