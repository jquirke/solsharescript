# Allume Energy / SolCentre API

Reverse-engineered from the SolCentre customer portal JS bundle.

## Base URL

```
https://api.allumeenergy.com.au/v2
```

## Authentication

### Login

```
POST /auth/customer-login
Content-Type: application/json

{ "email": "<email>", "password": "<password>" }
```

**Response `201 Created`:**
```json
{
  "accessToken": "<JWT>",
  "user": {
    "id": "<userId>",
    "email": "<email>",
    "firstName": "<firstName>",
    "lastName": "<lastName>",
    "role": "Consumer",
    "activated": true,
    "tcAccepted": true,
    "emailVerified": true,
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

The `accessToken` is a JWT. All subsequent requests must include:

```
Authorization: Bearer <accessToken>
```

---

## Consumer Endpoints

### Get My Properties

```
GET /consumers/me/properties
```

**Response `200 OK`:**
```json
{
  "email": "...",
  "properties": [
    {
      "id": "<propertyId>",
      "meterId": "<meterId>",
      "projectId": "<projectId>",
      "siteId": "<siteId>",
      "consumerId": "<consumerId>",
      "address1": "<unit>",
      "address2": "<street address>",
      "NMI": "<NMI>",
      "billingFrom": "2026-02-24T00:00:00.000Z",
      "isInvoiceEnabled": false,
      "calcStrategy": "Standard",
      "isSnapshotEnabled": true,
      "remark": ""
    }
  ]
}
```

---

## Energy Snapshot Endpoints

Date parameters (`from`, `to`) are **Unix timestamps in seconds** (not milliseconds).
The `to` value is exclusive — to fetch a single day, set `to = from + 86400`.

### Hourly Snapshots by Property

```
GET /properties/{propertyId}/snapshots?type=hourly&from={unixSecs}&to={unixSecs}
```

**Example** — fetch 25 Feb 2026:
```
GET /properties/<propertyId>/snapshots?type=hourly&from=1771977600&to=1772064000
```

**Response `200 OK`** — array of hourly records:
```json
[
  {
    "startAt": "2026-02-25T00:00:00.000Z",
    "endAt":   "2026-02-25T01:00:00.000Z",
    "energyDemand":     0.28,
    "solarConsumed":    0.28,
    "solarDelivered":   0.52,
    "solarExported":    0.23,
    "emissionReduced":  0.348244,
    "emissionReducedUnit": "kg"
  },
  ...
]
```

| Field | Unit | Description |
|---|---|---|
| `startAt` / `endAt` | ISO 8601 | Start and end of the hour window |
| `energyDemand` | kWh | Total electricity consumed by the property |
| `solarConsumed` | kWh | Solar energy actually used by the property |
| `solarDelivered` | kWh | Solar energy delivered to the property (consumed + exported) |
| `solarExported` | kWh | Solar energy exported to the grid from the property |
| `emissionReduced` | kg CO₂ | Emissions avoided by using solar |

**Derived values:**
- `gridImport = energyDemand - solarConsumed`
- `solarSelfConsumptionRate = solarConsumed / solarDelivered`

### Hourly Snapshots by Project

```
GET /projects/{projectId}/snapshots?type=hourly&from={unixSecs}&to={unixSecs}
```

### Hourly Snapshots by Meter

```
GET /meters/{meterId}/snapshots?type=hourly&from={unixSecs}&to={unixSecs}
```

---

## Other Discovered Endpoints

These were found in the JS bundle but are not the focus of this project.

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/register` | Register new consumer |
| `POST` | `/auth/forget-password` | Request password reset |
| `POST` | `/auth/reset-password` | Complete password reset |
| `POST` | `/auth/change-email` | Change email address |
| `POST` | `/auth/change-pwd` | Change password |
| `DELETE` | `/auth/delete-account/{id}` | Initiate account deletion |
| `GET` | `/projects/{id}` | Get project details |
| `GET` | `/projects/{id}/alerts` | Get alert configuration |
| `GET` | `/projects/{id}/batteries` | Get battery info |
| `GET` | `/meters/{id}/properties` | Get properties for a meter |
| `GET` | `/meters/{id}/revenue` | Get meter revenue data |
| `GET` | `/meters/{id}/property-savings` | Get property savings data |
| `GET` | `/snapshot/{id}/csv` | Download snapshot as CSV |
| `GET` | `/payment/subscription` | Get subscription details |
| `GET` | `/service-interface/system-info/{id}` | Get SolShare system info |

---

## Notes

- The portal is a Vue.js SPA served from `https://solcentre.allumeenergy.com`
- The API is at a separate origin (`api.allumeenergy.com.au`)
- JWT tokens have a ~14-day expiry (`exp` claim)
- Timestamps in API responses are UTC; the `$g()` frontend function passes a UTC offset as a third parameter to snapshot calls — this may affect how daily boundaries are computed server-side
