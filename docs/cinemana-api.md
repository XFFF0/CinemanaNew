# Cinemana App API Endpoints (v5.3.3)

Extracted from APK via static analysis (jadx/apktool).

---

## Base URLs

| Service | Base URL |
|---|---|
| **Main API** | `https://cinemana.shabakaty.com/api/android/` |
| **Analytics** | `https://cinemana.shabakaty.com` |
| **Account/User Management** | `https://account.shabakaty.com/` |
| **Content Delivery (CDN)** | `https://cnth2.shabakaty.com/` |
| **Recommendations** | `https://recommend.shabakaty.com/api/recommendation/recommend/` |
| **App Updates** | `https://updates.shabakaty.com/api/apps/7` |
| **Utility/IP Check** | `https://share.shabakaty.com/whatismyip` |
| **Status Page** | `https://6b1m6vnfz2jk.statuspage.io/api/v2/components.json` |
| **Zendesk Support** | `https://shabakaty.zendesk.com` |

---

## Main API Endpoints (ApiServices.kt)

**Base:** `https://cinemana.shabakaty.com/api/android/`

### GET Endpoints

| Endpoint | Description | Parameters |
|---|---|---|
| `allVideoInfo/id/{videoNb}` | Get video details | `videoNb` (path), `Cache-Control` (header) |
| `categories` | List categories | `Cache-Control` (header) |
| `getCollection/collectionID/{id}/level/{parentalLevel}` | Get collection | `id`, `parentalLevel` (path), `Cache-Control` (header) |
| `AdvancedSearch` | Advanced search | `videoTitle`, `staffTitle`, `type`, `year`, `category_id`, `star`, `page`, `level` (query) |
| `collectionsId/level/{parentalLevel}` | List collections | `parentalLevel` (path), `Cache-Control` (header) |
| `userSettings/lang/{language}` | User settings | `language` (path) |
| `memberCheckVideoStatus/id/{videoNb}` | Membership status | `videoNb` (path) |
| `videoSeason/id/{rootEpisodeId}` | Video season/episodes | `rootEpisodeId` (path), `Cache-Control` (header) |
| `banner/level/{parentalLevel}` | Banners | `parentalLevel` (path), `Cache-Control` (header) |
| `newlyVideosItems/level/{parentalLevel}/offset/12/` | Newly added | `parentalLevel` (path) |
| `videoComment/id/{videoNb}` | Video comments | `videoNb` (path) |
| `videoGroups/lang/{language}/level/{parentalLevel}` | Home page groups | `language`, `parentalLevel` (path), `Cache-Control` (header) |
| `commentRules` | Comment rules | none |
| `video/V/2` | Video list (paginated) | `categoryNb`, `videoKind`, `langNb`, `itemsPerPage`, `pageNumber`, `level`, `sortParam` (query), `Cache-Control` (header) |
| `videoListPagination` | Paginated video list | `groupID`, `level`, `itemsPerPage`, `page` (query) |
| `staff/actorID/{actorID}/level/{level}` | Staff/actor info | `actorID`, `level` (path) |
| `transcoddedFiles/id/{videoNb}` | Transcoded file URLs | `videoNb` (path), `Cache-Control` (header) |

### POST Endpoints (FormUrlEncoded)

| Endpoint | Description | Form Parameters |
|---|---|---|
| `logout/` | Logout | `deviceId` |
| `addLike/` | Add like | `userId`, `videoId`, `likeValue` |
| `commentSpam/` | Report spam comment | `userID`, `videoID`, `commentID` |
| `removeFromHistory/` | Remove from history | `userId`, `videoId`, `kind` |
| `history/` | Watch history | `pageNumber`, `userId`, `kind` |
| `addComment/` | Add comment | `id` (userId), `videoId`, `comment` |
| `changeParentalLevel` | Change parental level | `parentalLevel` |
| `highlightEpisode/` | Highlight episode | `videoID` |
| `UserTranslationSettings` | Translation settings | `enableNonTranslation` |
| `get_subscriptions` | Get subscriptions | none |
| `get_notifications` | Notifications | `count` |
| `updateComment/` | Update comment | `id`, `videoId`, `commentId`, `comment` |
| `login/` | Login | `deviceId`, `deviceName`, `playerId` |
| `addToHistory/` | Add to history | `userId`, `videoId`, `kind` |
| `add_subscriptions/` | Subscribe | `userId`, `video_id` |
| `removeComment/` | Remove comment | `id`, `videoId`, `commentId` |
| `remove_subscriptions/` | Unsubscribe | `userId`, `video_id` |

### Dynamic POST

| Description | URL |
|---|---|
| Recommendations (body sent as JSON) | `https://recommend.shabakaty.com/api/recommendation/recommend/` |

---

## Analytics Endpoints

**Base:** `https://cinemana.shabakaty.com`

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/info/ShabakatyInfo` | Send analytics events |

**POST params (FormUrlEncoded):** `deviceType`, `userID`, `identifier`, `platform_type`, `analytics` (JSON array)

---

## Account / User Management API

**Base:** `https://account.shabakaty.com/`

| Method | Endpoint | Description |
|---|---|---|
| POST | `core/api/password` | Change password |
| POST | `core/api/password/mobile-forgot-password` | Forgot password |
| POST | `core/connect/token` | Login (get tokens) |
| GET | `core/connect/facebook` | Facebook login |
| GET | `core/connect/google` | Google login |
| GET | `core/connect/userinfo` | Get user info |
| POST | `core/connect/token` | Refresh tokens |
| POST (Multipart) | `core/api/registration` | Register |
| POST | `core/api/password/mobile-reset` | Reset password |
| PATCH (Multipart) | `core/api/account/picture` | Update profile picture |
| POST | `core/api/account` | Update account info |
| GET | `core/api/device` | Verify device with user code |

---

## Additional Endpoints

| URL | Purpose |
|---|---|
| `https://cinemana.shabakaty.com/api/info/userInfo` | Get user info (direct call) |
| `https://cinemana.shabakaty.com/whatismyip` | Get client IP |
| `https://cinemana.shabakaty.com/hacheckphp.php` | Health check / availability |
| `https://cinemana.shabakaty.com/defaultImages/loading.gif` | Default loading image |
| `https://api.ipify.org/?format=json` | Get public IP (fallback) |
| `https://music-1539414046135.firebaseio.com` | Firebase Realtime Database (music) |
| `http://shstore.com/cin` | App store link |

---

## Annotation Mapping

The code is obfuscated with ProGuard/R8. Custom annotations map to Retrofit:

| Obfuscated | Actual Retrofit |
|---|---|
| `@i93` | `@POST` |
| `@lo1` | `@GET` |
| `@j93` | `@PATCH` |
| `@vh1` | `@FormUrlEncoded` |
| `@rv2` | `@Multipart` |
| `@la1` | `@Field` |
| `@va3` | `@Path` |
| `@ok3` | `@Query` |
| `@os1` | `@Header` |
| `@sm` | `@Body` |
| `@sa3` | `@Part` |
