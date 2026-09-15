# Other Code Findings

## `lib/data/repositories/mock_aci_repository.dart`

This file contains mock data intended only for development and UI testing before a real API was available. It should be removed from the production build or strictly isolated to development environments to ensure no mock data is accidentally exposed to end users.

**Code to be reviewed for removal/isolation:**

```dart
// ===========================================================================
//  mock_aci_repository.dart  =  SURSA "DATE DE TEST"
// ---------------------------------------------------------------------------
//  Intoarce date fixe, ca sa poti construi si vedea ecranele native inainte
//  sa existe API-ul (sau fara sa te loghezi). Simuleaza si o mica intarziere,
//  ca sa vezi cum arata aplicatia in timp ce "incarca".
// ===========================================================================

import '../models/account.dart';
import '../models/account_activity.dart';
import '../models/contact_option.dart';
import '../models/consumption_point.dart';
import '../models/consumption_record.dart';
import '../models/invoice.dart';
import '../models/linked_account.dart';
import '../models/meter_index.dart';
import '../models/payment_record.dart';
import '../models/portal_config.dart';
import 'aci_repository.dart';

class MockACIRepository implements ACIRepository {
  @override
  Future<Account> getAccount() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Account(
      holderName: 'Client demonstrativ',
      clientCode: 'CLIENT_TEST',
      address: 'Adresa demonstrativa',
      balance: -87.50,
    );
  }

  // ... (The rest of the mock implementation methods)
  // See `lib/data/repositories/mock_aci_repository.dart` for full source.
}
```

## `lib/data/repositories/api_aci_repository.dart`

According to `AUDIT/PAGES_REAL_API_STATUS.md`, the `ApiACIRepository` contains TODOs for the future official API and is currently unused in the build. It should be either completed if the API is ready, or kept separate until the official API is published.

**Explanation:**
The current `AppConfig.dataSource` uses `DataSource.cookie`. When transitioning to the real API, this repository will need to be fully implemented and `AppConfig.dataSource` switched to `DataSource.api`.
