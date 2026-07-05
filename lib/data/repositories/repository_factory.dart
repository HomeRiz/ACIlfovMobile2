// ===========================================================================
//  repository_factory.dart  =  "COMUTATORUL" DE SURSA DE DATE
// ---------------------------------------------------------------------------
//  Alege automat implementarea potrivita, in functie de AppConfig.dataSource.
//  Aici se vede cat de usoara e tranzitia: schimbi valoarea din AppConfig si
//  aceasta functie livreaza automat sursa corecta, fara sa atingi ecranele.
// ===========================================================================

import '../../core/config/app_config.dart';
import 'aci_repository.dart';
import 'api_aci_repository.dart';
import 'cookie_aci_repository.dart';
import 'mock_aci_repository.dart';

ACIRepository createRepository() {
  switch (AppConfig.dataSource) {
    case DataSource.mock:
      return MockACIRepository();
    case DataSource.cookie:
      return CookieACIRepository();
    case DataSource.api:
      return ApiACIRepository();
  }
}
