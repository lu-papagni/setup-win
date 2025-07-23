# Script di setup per Windows

## Introduzione
Ogni volta che capita di reinstallare Windows il processo di ricostruzione dell'ambiente che si
aveva in precedenza è lungo e fastidioso.
Le parti che portano via la maggior parte del tempo sono solitamente installare 
nuovamente tutto il software e riconfigurarlo come era prima.

Ho creato questo script per automatizzare queste operazioni e semplificare la riproducibilità
di Windows, come lo è già per diverse distribuzioni Linux.

## Requisiti minimi
- PowerShell 5.0
- Windows 10, build 1809

> [!NOTE]
> L'unico vero requisito è PowerShell, ma per avere la funzionalità di installazione
> automatica dei programmi **senza dipendenze di terze parti** è necessario 
> che sia installato [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/),
> il gestore dei pacchetti disponibile da Windows 10.
> È comunque possibile usare un gestore alternativo, ad esempio [scoop](https://scoop.sh/) o
> [chocolatey](https://chocolatey.org/install), ma richiede configurazione aggiuntiva.

## Uso
1. Clonare la repository o scaricarla come zip
2. Avviare PowerShell come **amministratore**
3. Lanciare lo script `Setup.ps1`

> [!IMPORTANT]
> Assicurarsi che la [policy di esecuzione](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)
> degli script sia impostata su `RemoteSigned`.
> Per verificarlo basta aprire powershell ed eseguire `Get-ExecutionPolicy`.
> Se necessario si può impostare usando `Set-ExecutionPolicy RemoteSigned` con il
> parametro `-Scope` valorizzato a `Process` per abilitarla solo per la sessione corrente
> oppure `LocalUser` per renderla permanente per il proprio utente.

## Sintassi
Lo script usa una sintassi simile a quella dei _cmdlet_ di PowerShell:
```
.\Setup.ps1 [-DryRun] [-Config 'percorso\della\configurazione.json'] [-Dotfiles 'percorso\file\backup\'] [-Only <Install|Import>]
```

| Parametro | Default | Tipo | Descrizione |
|---|---|---|---|
| DryRun | false | `Switch` | Serve per testare lo script, visualizza solo ciò che sarebbe successo + info di debug |
| Config | setup-config.json | `String` | Specifica il percorso relativo o assoluto del file di configurazione |
| Dotfiles | ~/dots-win | `String` | Specifica il percorso relativo o assoluto della cartella contenente i file di backup con le configurazioni dei tuoi programmi |
| Only | null | `"Install" \| "Import"` | Seleziona un'operazione tra quelle che lo script può compiere. Se non viene specificato nulla vengono eseguite tutte.|

## Funzionalità
1. Installare programmi usando un package manager
2. Importare le configurazioni corrispondenti creando collegamenti simbolici

Tutte le funzioni sono idempotenti, cioè se eseguite più volte di seguito il risultato sarà lo stesso della prima volta.

Il comportamento è personalizzabile attraverso un file di configurazione.
- I valori di default sono contenuti nel file `setup-config.json` nella radice del progetto.
- È supportato il *merge* delle impostazioni: fornendo un proprio file come parametro si possono sovrascrivere
i settaggi della [configurazione principale](https://github.com/lu-papagni/setup-win/blob/main/setup-config.json).

La configurazione deve essere in formato **JSON standard**.
Non possono esserci:
- Commenti
- Virgole che non precedono un elemento (_trailing comma_)

> [!WARNING]
> Un esempio di cosa NON fare.
> ```json
> {
>     "lista": [1, 2, 3,],    // virgola non ammessa nelle liste (vedi dopo il "3")
>     "numero": 69,           // stessa cosa alla fine della lista di attributi
>     // in generale non mettere MAI i commenti
> }
> ```

Da PowerShell 7.0 il parser permette di usare questa sintassi, ma per tutte le versioni precedenti fare in questo
modo risulterebbe in un errore.

Per un esempio reale vedere
[la mia configurazione](https://github.com/lu-papagni/dots-win/blob/main/setup-config.json).

### Installazione programmi
Richiede un dizionario con chiave `installPrograms`.
I programmi verranno installati usando il package manager definito dall'utente.

| Attributo | Tipo | Descrizione |
|---|---|---|
| enabled | `Boolean` | Determina se la funzionalità è abilitata. |
| collections | `Dict` | Contiene impostazioni riguardanti quali pacchetti installare e come farlo. |
| packageManager | `Dict` | Contiene le info sul package manager e le azioni che può compiere. |

*packageManager*
| Attributo | Tipo | Descrizione |
|---|---|---|
| name | `String` | Nome del package manager; deve essere eseguibile nel sistema. |
| actions | `Dict` | Collezione di comandi predefiniti che un package manager può compiere. |

*packageManager.actions*
| Attributo | Tipo | Descrizione |
|---|---|---|
| import | `String[]` | Comando per installare una lista di pacchetti. Ogni stringa è un argomento per `packageManager.name`. |
| update | `String[]` | Comando per aggiornare tutti i pacchetti registrati dal package manager. Ogni stringa è un argomento per `packageManager.name`. |

> [!NOTE]
> I comandi del package manager possono essere resi modulari. In particolare, l'azione
> `import` permette già di specificare un parametro posizionale `${0}`.
> Al momento, questo sistema viene
> [usato internamente](https://github.com/lu-papagni/setup-win/blob/f09e4559c35ac884ca1a9a4b15592f0d00029bc5/Modules/Installation.psm1)
> per segnalare dove inserire il percorso del file da cui importare i pacchetti.
> In generale questa soluzione può essere esposta per passare una serie di parametri, dove
> il numero nel segnaposto rappresenta l'indice di una stringa nella lista in input.

*collections*
| Attributo | Tipo | Descrizione |
|---|---|---|
| type | `String` | Estensione delle liste di pacchetti. |
| path | `true \| String` | Indica come trovare la directory contenente le liste. Se è `true`, viene scelta la directory in modo interattivo attraverso un dialog grafico. Altrimenti è un percorso relativo a `%USERPROFILE%`. |
| get | `String[]` | Nomi, senza estensione, dei file contenenti pacchetti installabili dal package manager utilizzato. |

### Importazione configurazione
Richiede un dizionario con chiave `configFiles`.
Effettua collegamenti simbolici di file e/o cartelle di configurazione nelle destinazioni specificate.

Per sfruttare la funzionalità è necessario avere una cartella strutturata in modo tale da contenere una **sotto-cartella per ogni programma**
che si vuole configurare.
I nomi delle sotto-cartelle:
- non sono legati al nome reale del programma
- costituiscono un ID che potrà essere usato per riferirsi agli elementi in essa contenuti

| Attributo | Tipo | Descrizione |
|---|---|---|
| enabled | `Boolean` | Determina se la funzionalità è abilitata. |
| programs | `Dict` | Indica quali file di configurazione considerare e dove collegarli per ogni programma. |

*programs*
| Attributo | Tipo | Descrizione |
|---|---|---|
| *user defined* | `Dict[]` | La chiave è il nome della sotto-cartella che contiene i file di configurazione di un certo programma.<br> Gli oggetti contengono informazioni su come i file devono essere individuati e linkati. |

*programs.\<cartella-sorgente\>*
| Attributo | Tipo | Descrizione |
|---|---|---|
| name | `RegEx` | Identifica uno o più elementi da prendere come bersaglio per essere collegati nella directory specificata.<br> Usare solo espressioni regolari compatibili con .NET (C#) |
| root | `String` | Variabile d'ambiente che contiene un percorso di sistema.<br> Ad esempio: `USERPROFILE`, `APPDATA`, ecc. |
| destination | `String` | Percorso che identifica una sotto-cartella relativamente a quella dell'attributo `root`. Se non esiste verrà creata. |

Ad esempio, per una cartella con questa struttura:
```
<Dotfiles>
│
├───programma1
│       file1.a
│       file2.b
│
├───programma2
│   │   file3
│   │
│   └───sottocartella21
│       └───sottocartella211
│               file4
...

```
Una possibile configurazione sarà:
```json
{
    "configFiles": {
        "programma1": [
            {
                "root": "PROGRAMFILES",
                "destination": "programma1\\a",
                "name": "\\w*\\.a"
            },
            {
                "root": "PROGRAMFILES",
                "destination": "programma1\\b",
                "name": "\\w*\\.b"
            }
        ],
        "programma2": [
            {
                "root": "PROGRAMFILES(X86)",
                "destination": "programma2",
                "name": "file3"
            }
        ],
        "programma2/sottocartella21": [
            {
                "root": "APPDATA",
                "destination": "programma2",
                "name": "sottocartella\\d+"
            }
        ]
    }
}
```
Risultato:
- Collega tutti i file `.a` in `programma1` nella sotto-cartella `a` in `%PROGRAMFILES%\programma1`; analogamente per i file `.b`.
- Collega `file3` in `%PROGRAMFILES(x86)%\programma2`.
- Collega tutte le cartelle che iniziano per `sottocartella` e terminano con un numero presenti in `programma2\sottocartella21`
nella destinazione `%APPDATA%\programma2`.
L'operazione non è ricorsiva, infatti viene creato semplicemente un riferimento alla vera cartella.

> [!TIP]
> Nei percorsi è indifferente usare il forward slash o il backslash. Tuttavia, usando il backslash, è necessario
> scriverlo come `\\` perché il singolo `\` è il carattere di escape del JSON.

