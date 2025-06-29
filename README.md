# Framework per il Security Assessment di un’Infrastruttura Google Cloud Platform (GCP)
More actions



Il progetto implementa un framework, basato su script bash, per il Security Assessment delle impostazioni di configurazione di un progetto Google Cloud Platform
(GCP). Il meccanismo di audit è stato implementato tenendo conto di un sottoinsieme delle
raccomandazioni contenute nel CIS Benchmarks per GCP. Si intende, con la presente repo, fornire una Proof of Concept
che funga da punto di partenza per lo sviluppo di strumenti da usare in produzione.



## Organizzazione del progetto

Di seguito è riportata una breve descrizione del contenuto delle diverse path del progetto.





`/src/checks`: contiene gli script per l'esecuzione dei controlli

`/src/setup/sample-env1` contiene gli script utilizzati per la creazione e la configurazione
del Progetto 1 (maggiori dettagli nella documentazione)

`/src/setup/sample-env2` contiene gli script utilizzati per la creazione e la configurazione
del Progetto 2 (maggiori dettagli nella documentazione)

`GCP_SA_report.pdf`: è la documentazione del progetto.





## Istruzioni per l'uso

Dopo aver installato Google Cloud CLI. eseguire le operazioni seguenti:


**1.** Installare le ulteriori dipendenze necessarie
```
sudo apt install jq
```


**2.** Rimuovere eventuali account e/o progetti GCP precedentemente impostati.
```
gcloud config unset account
gcloud config unset project
```

**3.** Autenticarsi con un account che ha il permesso di accedere al progetto su cui si intende
utilizzare il framework.

```
gcloud auth application-default login
```


**4.** Impostare il progetto su cui eseguire i controlli e di cui consumare le quote
al momento dell'invocazione delle API.

```
gcloud config set project <PROJECT-ID>
gcloud auth application-default set-quota-project <PROJECT-ID>
```


**5.** Utilizzare gli script di verifica in `/src/checks`. Lo script `/src/checks/check-all.sh`
richiede di specificare su linea di comando
l’ID del progetto GCP da analizzare e il dominio autorizzato; quest’ultima informazione è
necessaria per eseguire il controllo **3.2** del **GCP CIS Benchmarks**, riferito all’eventuale presenza, all’interno del progetto,
di utenti appartenenti a un dominio diverso da quello specificato


## Autori e contatti

| Autore              | Indirizzo email                 |
|---------------------|---------------------------------|
| Francesco Giorgione | francesco.giorgione01@gmail.com |