# Script di setup per Windows

## Compatibilità
Lo script è compatibile con tutti i PC Windows con una versione di **PowerShell** >= `5.0`.

## Uso
1. Clonare la repository
2. Avviare `powershell` come **amministratore** e impostare la directory di lavoro su quella dello script
3. Lanciare lo script `Setup.ps1`

## Sintassi
Lo script usa una sintassi simile a quella dei _cmdlet_ di PowerShell:
```ps1
.\Setup.ps1 [-DryRun] [-Config 'percorso\della\configurazione.json']
```

Parametri:
| Nome | Default | Descrizione |
|---|---|---|
| DryRun | `$false` | Serve per testare lo script, visualizza solo ciò che sarebbe successo + info di debug |
| Config | `setup-config.json` | Specifica il percorso relativo o assoluto del file di configurazione |

## Formato
Il file di configurazione deve essere un file **JSON standard**.
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

Da PowerShell `7.x` è permessa questa sintassi. Per tutte le versioni precedenti fare in questo modo risulterebbe
in un crash.

## Funzionalità
Per un esempio completo vedere
[setup-config.json](https://github.com/lu-papagni/dots-win/blob/67216153255d0409bf8ac303a45fa047856b62c7/setup-config.json)

### Installazione programmi
La configurazione deve contenere un oggetto con chiave `installPrograms`.
I programmi verranno installati usando il package manager definito dall'utente.

**Proprietà**
<table>
    <tr>
        <th>Chiave</th>
        <th>Tipo</th>
        <th>Descrizione</th>
    </tr>
    <tr>
        <td>enabled</td>
        <td>Booleano</td>
        <td>Determina se la funzionalità è abilitata</td>
    </tr>
    <tr>
        <td>lists</td>
        <td>Lista di stringhe</td>
        <td>
            Nomi dei file JSON nella directory <code>Packages</code>,
            senza estensione, che corrispondono a backup di <code>winget</code>.
        </td>
    </tr>
    <tr>
        <td>packageManager</td>
        <td>Oggetto</td>
        <td>Contiene le info sul package manager e le azioni che può compiere.</td>
    </tr>
</table>

**Struttura di `packageManager`**
<table>
    <tr>
        <th>Chiave</th>
        <th>Tipo</th>
        <th>Descrizione</th>
    </tr>
    <tr>
        <td>name</td>
        <td>Stringa</td>
        <td>
            Nome del package manager. Verrà usato per controllare la sua presenza nel sistema,
            dopodiché come primo elemento di ogni comando.
        </td>
    </tr>
    <tr>
        <td>actions</td>
        <td>Oggetto</td>
        <td>
            Una serie di coppie chiave - valore, dove la chiave è una stringa (il nome dell'azione) e
            il valore è una lista di stringhe, dove ognuna è un parametro per quella determinata azione.
            Le azioni supportate sono <code>update</code> e <code>import</code>: la prima specifica come
            il package manager aggiorna l'intero sistema; il secondo come importa una serie di pacchetti
            da installare.
        </td>
    </tr>
</table>

> [!NOTE]
> I comandi del package manager possono essere resi modulari. In particolare, l'azione
> `import` permette già di specificare un parametro posizionale `${0}`.
> Al momento, questo sistema viene [usato internamente](https://github.com/lu-papagni/setup-win/blob/f09e4559c35ac884ca1a9a4b15592f0d00029bc5/Modules/Installation.psm1)
> per segnalare dove inserire il percorso del file da cui importare i pacchetti.
> In generale questa soluzione può essere esposta per passare una serie di parametri, dove
> il numero nel segnaposto rappresenta l'indice di una stringa nella lista in input.

### Importazione file di configurazione
Controllato dall'oggetto con chiave `configFiles`.
Effettua collegamenti simbolici tra i file nella cartella che contiene
il file di configurazione e le destinazioni specificate.

**Proprietà**
<table>
    <tr>
        <th>Chiave</th>
        <th>Tipo</th>
        <th>Descrizione</th>
    </tr>
    <tr>
        <td>enabled</td>
        <td>Booleano</td>
        <td>Determina se la funzionalità è abilitata</td>
    </tr>
    <tr>
        <td>programs</td>
        <td>Oggetto</td>
        <td>Contiene informazioni sul programma ed i suoi file. Vedi la tabella seguente.</td>
    </tr>
</table>

**Struttura di un attributo di `programs`**
<table>
    <tr>
        <th>Chiave</th>
        <th>Tipo</th>
        <th>Descrizione</th>
    </tr>
    <tr>
        <td><i>user defined</i></td>
        <td>Lista di oggetti</td>
        <td>
            La chiave è il nome <b>user defined</b> della sotto-cartella che
            contiene i file di configurazione di un certo programma.
            Gli oggetti contengono informazioni su come i file devono essere individuati e linkati.
            Vedere la tabella seguente.
        </td>
    </tr>
</table>

**Struttura di info sui file**
<table>
    <tr>
        <th>Chiave</th>
        <th>Tipo</th>
        <th>Descrizione</th>
    </tr>
    <tr>
        <td>name</td>
        <td>Espressione regolare</td>
        <td>
            Identifica uno o più file che verranno presi come bersaglio per essere
            linkati nella directory specificata.
            <b>Nota:</b> il backslash ha bisogno di escaping in JSON.
        </td>
    </tr>
    <tr>
        <td>root</td>
        <td>Stringa</td>
        <td>
            Variabile d'ambiente che contiene un percorso di sistema.
            Ad esempio: <code>USERPROFILE</code>, <code>APPDATA</code>, ecc.
        </td>
    </tr>
    <tr>
        <td>destination</td>
        <td>Stringa</td>
        <td>
            Percorso che identifica una sotto-cartella di quella derivata
            dall'attributo <code>root</code>.
            Se non esiste verrà creata.
        </td>
    </tr>
</table>
