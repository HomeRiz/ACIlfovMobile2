# ACIlfovMobile2 - status pagini si date reale

Data audit: 2026-07-07

Sursa activa este `DataSource.cookie`, deci aplicatia foloseste sesiunea reala
din portalul ACIlfov/EMSYS. `MockACIRepository` ramane doar pentru dezvoltare
daca se schimba explicit `AppConfig.dataSource`.

## Pagini din meniu

| Pagina | Status | Endpoint-uri principale |
| --- | --- | --- |
| Acasa | Date reale | `contract/getListaCodClientContracte`, `facturi/getSoldClient`, facturi/index |
| Istoric facturi | Date reale | `facturi/Facturis`, sortare `DATA_DOC desc` |
| Transmitere index | Date reale | `transmitere/puncteConsums`, `transmitere/Transmiteres`, `transmitere/add` |
| Istoric plati | Date reale | `plati/Platis` |
| Istoric consum | Date reale | `consum/getPuncteConsumValide`, `consum/getContoare`, `consum/Consums` |
| Grafic | Date reale | Refoloseste istoricul de consum |
| Actualizare date cont | Date reale | `contract/getListaCodClientContracte`, `addClientContract`, `addContract`, `deleteCodClient` |
| Configurari | Date reale | `cofiguri/Configuris`, `activare`, `dialogDezactiveaza`, `configAlerte/*` |
| Schimbare parola | Date reale | `portaluserobj/changePassword` |
| Contact | Date reale | `contact/codClients`, `motives`, `subiectes`, `getLungimeMesaj`, `sendMessage` |
| Informatii cont | Date reale | `informatiiCont/InformatiiConts`, sortare `DATA_OPERATIE desc` |
| Stergere cont | Date reale | `portaluserobj/stergereCont` |
| Info | Link-uri oficiale | `acilfov.ro` si portal extern |

## Ce mai necesita validare pe cont real

- Contact: endpoint-ul de upload atasament exista in portal
  (`contact/upload/attachment`), dar build-ul curent trimite formularul fara
  atasament. Mesajele simple sunt conectate la `sendMessage`.
- Configurari alerte: activarea cere email/telefon in dialogul mobil; trebuie
  validat cu raspunsurile reale ale contului pentru fiecare tip de alerta.
- Transmitere index: payload-ul este preluat din randul real EMSYS si trimis la
  `transmitere/add`; trebuie testat numai intr-o perioada in care portalul
  permite transmiterea indexului.
- `ApiACIRepository` contine in continuare TODO-uri pentru viitorul API oficial,
  dar nu este folosit in build-ul curent.
