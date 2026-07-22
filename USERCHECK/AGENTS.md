## Instructiuni importate din Claude Cowork

## Flux pentru build si instalare mobila

Cand aplicatia este testata pe emulator Android, simulator iOS sau dispozitiv fizic, dezinstaleaza orice varianta instalata anterior inainte sa instalezi un build nou.

Pentru Android, verifica pachetele asociate, inclusiv `ro.acilfov.mobile` si identificatorii mai vechi folositi in testare, apoi instaleaza APK-ul proaspat construit.

Build-ul trebuie facut pentru ABI-ul dispozitivului tinta: build-urile x86/x64 sunt pentru emulatoare, iar telefoanele Android fizice au nevoie de librarii ARM, de exemplu `arm64-v8a` sau `armeabi-v7a`.
