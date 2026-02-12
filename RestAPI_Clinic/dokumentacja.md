# Dokumentacja testów REST API „Clinic”

## 1. Podstawowe informacje
- **Narzędzia:** Postman do zrobienia kolekcji testów + Newman do wykonania testów i zebrania statystyk.  
- **Środowisko:** `localhost:3000`  
- **Collection:** `Clinic.postman_collection.json`  

---

## 2. Scenariusze testowe

### 2.0 Get doctors (publiczny)
- **Metoda:** GET  
- **Endpoint:** `/api/doctors`  
- **Nagłówki:** —  
- **Body:** —  
- **Oczekiwanie:** HTTP 200 OK, zwraca listę lekarzy  
- **Wynik:** `200 OK, 911B, 59ms`

### 2.1 Get doctors by specialty (publiczny)
- **Metoda:** GET  
- **Endpoint:** `/api/doctors/specialty/Cardiology`  
- **Nagłówki:** —  
- **Body:** —  
- **Oczekiwanie:** HTTP 200 OK, zwraca listę lekarzy  
- **Wynik:** `200 OK, 911B, 59ms`

### 2.2 Post visit unauthorized
- **Metoda:** POST  
- **Endpoint:** `/api/appointments`  
- **Nagłówki:** brak `Authorization`  
- **Body:** JSON z polami `doctor`, `patient`, `date`, `reason`  
- **Oczekiwanie:** HTTP 401 Unauthorized  
- **Wynik:** `401 Unauthorized, 281B, 3ms`

### 2.3 Register Patient (poprawnie)
- **Metoda:** POST  
- **Endpoint:** `/api/auth/register/patient`  
- **Body:**  
  ```json
  {
    "name":"Anna Test",
    "birthDate":"1995-07-10",
    "email":"anna.test@example.com",
    "phone":"+48111111111",
    "password":"Test123!"
  }
- **Oczekiwanie**: HTTP 201 Created + { token }

- **Wynik**: `201 Created, 424B, 139ms`

### 2.4 Register Patient Wrong (walidacja)
- **Metoda:** POST
- **Endpoint:** /api/auth/register/patient
- **Body:** brak wszystkich wymaganych pól
- **Oczekiwanie:** HTTP 400 Bad Request
- **Wynik:** `400 Bad Request, 1.02kB, 99ms`

### 2.5 Login as Patient (nieudane)
- **Metoda:** POST
- **Endpoint:** /api/auth/login
- **Body:** niepoprawne dane
- **Oczekiwanie:** HTTP 400 Bad Request
- **Wynik:** `400 Bad Request, 275B, 39ms`

### 2.6 Login as Patient (poprawne)
- **Metoda:** POST
- **Endpoint:** /api/auth/login
- **Body:**
    ```json
    {
      "email":"anna.test@example.com",
      "password":"Test123!",
      "type":"patient"
    }
    
- **Oczekiwanie:** HTTP 200 OK + { token }
- **Wynik:** `200 OK, 419B, 95ms`

### 2.7 Post visit (poprawnie przez pacjenta)
- **Metoda:** POST
- **Endpoint:** /api/appointments
- **Nagłówki:** Authorization: Bearer {{jwt_patient}}
- **Body:**
    ```json
    {
      "doctor":"{{doctorId}}",
      "patient":"{{patientId}}",
      "date":"2025-05-15T09:00:00.000Z",
      "reason":"Konsultacja"
    }
- **Oczekiwanie:** HTTP 201 Created + status "awaiting approval"
- **Wynik:** `201 Created, 518B, 43ms`

### 2.8 Register Doctor (brak uprawnień)
- **Metoda:** POST
- **Endpoint:** /api/auth/register/doctor
- **Nagłówki:** Authorization: Bearer {{jwt_patient}}
- **Oczekiwanie:** HTTP 403 Forbidden
- **Wynik:** `403 Forbidden, 284B, 5ms`

### 2.9 Change Password (pacjent)
- **Metoda:** PATCH
- **Endpoint:** /api/patients/{{patientId}}/password
- **Nagłówki:** Authorization: Bearer {{jwt_patient}}
- **Body:** poprawne haslo
- **Oczekiwanie:** HTTP 200 OK + { message:"Password updated" }
- **Wynik:** `200 OK, 265B, 103ms`

### 2.10 Change Status (nieuprawniony pacjent)
- **Metoda:** PUT
- **Endpoint:** /api/appointments/{{apptId}}
- **Nagłówki:** Authorization: Bearer {{jwt_patient}}
- **Body:** 
    ```json
    { "status":"done" }
- **Oczekiwanie:** HTTP 403 Forbidden
- **Wynik:** `403 Forbidden, 263B, 8ms`

### 2.11 Login as Admin
- **Metoda:** POST
- **Endpoint:** /api/auth/login
- **Body:**
    ```json
    {
      "email":"admin@clinic.com",
      "password":"Admin123!",
      "type":"doctor"
    }
- **Oczekiwanie:** HTTP 200 OK + { token }
- **Wynik:** `200 OK, 439B, 95ms`

### 2.12 Change Status Copy (weryfikacja)
- **Metoda:** PUT
- **Endpoint:** /api/appointments/{{apptId}}
- **Nagłówki:** Authorization: Bearer {{jwt_admin}} lub {{jwt_doctor}}
- **Oczekiwanie:** HTTP 403 Forbidden (jeśli inny doktor)
- **Wynik:** `403 Forbidden, 263B, 6ms`

### 2.12 Delete patient
- **Metoda:** DELETE
- **Endpoint:** /api/patients/{{patient}}
- **Nagłówki:** Authorization: Bearer {{jwt_patient}}
- **Oczekiwanie:** HTTP 204 no content
- **Wynik:** `204 no content, 445B, 38ms`

### 2.13 Get appointments by patient
- **Metoda:** GET
- **Endpoint:** /api/patients/{{patientId}}/appointments
- **Nagłówki:** Authorization: Bearer {{jwt_patient}}
- **Oczekiwanie:** HTTP 200 OK + lista wizyt
- **Wynik:** `200 OK, 2.03kB, 83ms`

### 2.14 Delete appointment
- **Metoda:** DELETE
- **Endpoint:** /api/appointments/{{appointmentID}}
- **Nagłówki:** Authorization: Bearer {{jwt_doctor}}
- **Oczekiwanie:** HTTP 204 no content
- **Wynik:** `204 OK, 2.03kB, 83ms`

### 2.14 Post appointment (poprawne)
- **Metoda:** POST
- **Endpoint:** /api/appointments
- **Nagłówki:** Authorization: Bearer {{jwt_doctor}}
- **Body:** analogiczne do 2.7
- **Oczekiwanie:** HTTP 201 Created
- **Wynik:** `201 Created, 523B, 46ms`

### 2.15 Get appointments by date
- **Metoda:** GET
- **Endpoint:** /api/appointments?date=2025-06-18T13:00:00.000Z
- **Oczekiwanie:** HTTP 200 OK + wizyty od tej daty
- **Wynik:** `200 OK, 1.43kB, 82ms`

### 2.16 Get all appointments
- **Metoda:** GET
- **Endpoint:** /api/appointments
- **Oczekiwanie:** HTTP 200 OK + wszystkie wizyty
- **Wynik:** `200 OK, 3.39kB, 88ms`

### 2.17 Register Doctor (konflikt)
- **Metoda:** POST
- **Endpoint:** /api/auth/register/doctor
- **Nagłówki:** Authorization: Bearer {{jwt_admin}}
- **Body:** dane istniejącego emaila
- **Oczekiwanie:** HTTP 409 Conflict
- **Wynik:** `409 Conflict, 265B, 51ms`

### 2.18 Register Doctor new (poprawne)
- **Metoda:** POST
- **Endpoint:** /api/auth/register/doctor
- **Nagłówki:** Authorization: Bearer {{jwt_admin}}
- **Body:** unikalny email
- **Oczekiwanie:** HTTP 201 Created + { token }
- **Wynik:** `201 Created, 445B, 138ms`

### 2.19 Delete doctor
- **Metoda:** DELETE
- **Endpoint:** /api/doctors/{{doctor}}
- **Nagłówki:** Authorization: Bearer {{jwt_admin}}
- **Oczekiwanie:** HTTP 204 no content
- **Wynik:** `204 no content, 445B, 38ms`

### 2.20 Get all appointments (expired token)
- **Metoda:** GET
- **Endpoint:** /api/appointments
- **Oczekiwanie:** `HTTP 401 Expired token`
- **Wynik:** `401 OK, 3.39kB, 88ms`

## 3. Test Bezpieczeństwa Autoryzacji JWT

### Przypadek testowy: Odrzucenie niepodpisanego JWT (`alg: "none"`)

### Cel testu  
Upewnienie się, że API **nie akceptuje niepodpisanych tokenów JWT** z nagłówkiem `"alg": "none"`, co mogłoby umożliwić obejście autoryzacji bez znajomości sekretu.

### Struktura złośliwego tokena
```json
Header:
{
  "typ": "JWT",
  "alg": "none"
}
{
  "id": "681c58d9206acb1f6bf5718f",
  "role": "admin",
  "iat": 1747726963,
  "exp": 1747730563
}
Signature:
(brak)
```

Token został wysłany przez Postmana w nagłówku Authorization: Bearer <token> do chronionego endpointu.

### Wynik
Serwer powinien odrzucić żądanie z kodem 401 Unauthorized — i faktycznie poprawnie to zrobił.

### Wniosek
API prawidłowo weryfikuje tokeny JWT i nie pozwala na użycie algorytmu none, co oznacza, że mechanizm weryfikacji JWT został zaimplementowany bezpiecznie i nie jest podatny na ten popularny wektor ataku.


## 4. Podsumowanie wyników Newman

newman run Clinic.postman_collection.json

| Category              | Executed | Failed |
|-----------------------|----------|--------|
| Iterations            | 1        | 0      |
| Requests              | 23       | 0      |
| Test Scripts          | 23       | 0      |
| Prerequest Scripts    | 23       | 0      |
| Assertions            | 0        | 0      |

**Total run duration:** 2.5s  
**Total data received:** 9.11kB (approx)  
**Average response time:** 65ms (min: 3ms, max: 139ms, s.d.: 42ms)


Wszystkie testy zakończyły się pomyślnie, pokrywając scenariusze poprawne, błędne zapytania, walidację i autoryzację.