// ===========================================================================
//  mock_aci_repository.dart  =  SURSA "DATE DE TEST"
// ---------------------------------------------------------------------------
//  Intoarce date fixe, ca sa poti construi si vedea ecranele native inainte
//  sa existe API-ul (sau fara sa te loghezi). Simuleaza si o mica intarziere,
//  ca sa vezi cum arata aplicatia in timp ce "incarca".
// ===========================================================================

import '../models/account.dart';
import '../models/consumption_point.dart';
import '../models/consumption_record.dart';
import '../models/invoice.dart';
import '../models/meter_index.dart';
import 'aci_repository.dart';

class MockACIRepository implements ACIRepository {
  @override
  Future<Account> getAccount() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Account(
      holderName: 'Popescu Ion',
      clientCode: 'ACI-123456',
      address: 'Str. Exemplu nr. 10, Otopeni, Ilfov',
      balance: -87.50,
    );
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      Invoice(
        id: '1',
        number: 'ACI-2026-000123',
        issueDate: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 10)),
        amount: 87.50,
        paid: false,
      ),
      Invoice(
        id: '2',
        number: 'ACI-2026-000101',
        issueDate: now.subtract(const Duration(days: 35)),
        dueDate: now.subtract(const Duration(days: 20)),
        amount: 92.30,
        paid: true,
      ),
      Invoice(
        id: '3',
        number: 'ACI-2026-000078',
        issueDate: now.subtract(const Duration(days: 65)),
        dueDate: now.subtract(const Duration(days: 50)),
        amount: 79.10,
        paid: true,
      ),
    ];
  }

  @override
  Future<MeterIndex> getMeterIndex() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return MeterIndex(
      lastValue: 1420,
      lastReadDate: DateTime(now.year, now.month - 1, 26),
      // Regula ACIlfov: perioada de transmitere e de pe 25 pana la finalul lunii.
      windowStart: DateTime(now.year, now.month, 25),
      windowEnd: DateTime(now.year, now.month + 1, 0), // ultima zi a lunii
    );
  }

  @override
  Future<void> submitMeterIndex(int value) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Mock: nu trimite nimic real, doar simuleaza succesul.
  }

  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      ConsumptionPoint(
        idLocatie: '1',
        clientName: 'Popescu Ion',
        address: 'Str. Exemplu nr. 10, Otopeni, Ilfov',
        meters: ['60000001'],
      ),
    ];
  }

  @override
  Future<List<ConsumptionRecord>> getConsumption({
    required String idLocatie,
    required String contor,
    required DateTime start,
    required DateTime end,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = <ConsumptionRecord>[];
    var d = DateTime(start.year, start.month, 1);
    var index = 500;
    while (!d.isAfter(end)) {
      final consum = 8 + (d.month % 6);
      list.add(ConsumptionRecord(
        contor: contor,
        dataConsum: DateTime(d.year, d.month, 1),
        indexVechi: index,
        indexNou: index + consum,
        diferenta: consum,
        tipConsum: 'CITIRE',
        factura: '',
        dataEmitere: null,
      ));
      index += consum;
      d = DateTime(d.year, d.month + 1, 1);
    }
    return list.reversed.toList(); // cele mai noi sus
  }
}
