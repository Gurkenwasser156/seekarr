# Piano di Sviluppo: Miglioramenti Dettagli Media (Jellyseerr)

## Impostazioni e Regione
* Aggiungere un'opzione nelle Impostazioni per selezionare il Paese/Regione (utilizzato per watch providers, date di uscita, classificazione dei contenuti, ecc.).
* Precompilare il Paese utilizzando la lingua/locale del dispositivo, se disponibile.
* Paese di fallback predefinito: US (Stati Uniti).
* Se il Paese configurato non è presente nei dati, mostrare chiaramente all'utente uno stato tipo "non disponibile nella tua regione" (evitare l'uso silenzioso di dati di altri Paesi).

## Funzionalità e Dati Comuni
* Ignorare per il momento il campo `mediaInfo['path']`.
* **Elementi esclusi:** Non inserire tagline, homepage o punteggio di popolarità.

## Struttura UI e Layout Diretto (Ispirato a Jellyseerr Web)

### 1. Hero Section (Header)
* **Backdrop come Sfondo:** L'immagine `backdropPath` coprirà tutta la parte superiore dietro al contenuto, sfumando verso il colore di base dell'app tramite un gradiente scuro in basso.
* **Layout Centrato:** 
  * **Poster:** Centrato e visibile in primo piano sopra il backdrop.
  * **Status Badge:** Il chip dello stato ("Available", "Requested") posizionato tra il poster e il titolo (o subito sotto il titolo).
  * **Titolo:** Grande e centrato.
  * **Metadata Line:** Una singola riga di testo compatta e pulita: `[Content Rating] | [Anno] | [Runtime o "8 Seasons • 96 Episodes"] | [Generi]`.

### 2. Action & Rating Row
* **Ratings:** Subito sotto i metadata, una riga centrata con i voti (TMDB, e quelli ricavati da Radarr/Sonarr).
* **Azioni:** Una riga orizzontale di bottoni:
  * Bottone primario: "Request" o "Manage".
  * Bottone secondario **"Videos"**: apre la bottom sheet/dropdown con la lista dei trailer e video selezionabili.
  * Altri bottoni esistenti (es. Open in Radarr/Sonarr).

### 3. Overview
* Allineata a sinistra, font normale e leggibile. Stile pulito senza distrazioni, posizionata subito sotto l'header.

### 4. Cast, Crew & Keywords
* **Crew:** Griglia compatta a 2 colonne per Director, Screenplay, Producer, ecc.
* **Cast:** Lista a scorrimento orizzontale con avatar circolari e testo centrato.
* **Keywords:** Wrap di chip stile 'outlined' (con bordo e senza sfondo pieno).

### 5. Collection Banner (Solo Film)
* Se il film fa parte di una collection, mostrare una **Card full-width** orizzontale.
* Sfondo della card: il `backdropPath` della collection stessa, oscurata da un overlay.
* Testo bianco col nome della collection (ed eventualmente un pulsante "View").

### 6. TV Seasons (Solo Serie TV)
* Lista compatta sotto l'overview.
* Ogni riga mostra: `Titolo Stagione` (es. Season 1), `Numero episodi` allineato a destra, e un `Badge` di disponibilità Jellyseerr (mostrato in linea *solo* se lo stato è Available o Partially Available).

### 7. Watch Providers
* Sezione dedicata intitolata "Where to Watch".
* Divisa in due righe orizzontali (se dati presenti): **"Stream"** e **"Buy"**.
* Liste a scorrimento orizzontale di piccoli loghi arrotondati (es. Netflix, Apple TV).
* In assenza di provider per la regione configurata, mostrare lo stato "non disponibile nella tua regione".

### 8. Release Info / Facts Card
* Un blocco scuro riassuntivo posizionato in fondo alla pagina (usando una `AppCard` outlined o filled scura), per raccogliere i dati tecnici senza appesantire l'intestazione.
* **Per i Film:** Righe interne dedicate a `Theatrical Release`, `Digital Release`, `Physical Release`.
* **Per le Serie:** Righe interne dedicate a `First Aired`, `Last Aired`, `Next Episode`.