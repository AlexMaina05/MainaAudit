# ==========================================
# MainaAudit Tool - Professional Use
# Author: Alessandro Maina | alexmaina.dev
# ==========================================

# Forza la sessione PowerShell a usare UTF8 per l'output e l'input
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. SETUP AMBIENTE
$RootPath = "C:\MainaAudit"
$TemplatePath = Join-Path $RootPath "templates\report_base.md"
$OutputPath = Join-Path $RootPath "output"
$TempPath = Join-Path $RootPath "data"
$LogoPath = "C:/MainaAudit/assets/logo.png"

# Crea cartelle se mancano
if (!(Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }
if (!(Test-Path $TempPath)) { New-Item -ItemType Directory -Path $TempPath | Out-Null }

# 2. INPUT DATI
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     MAINA AUDIT SYSTEMS - v2.5 PRO       " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ClientName = Read-Host "Nome Cliente"
if ([string]::IsNullOrWhiteSpace($ClientName)) { $ClientName = "Analisi_Locale" }

# ==========================================
# SEZIONE 2: LIVE SCANNING (IL CERVELLO)
# ==========================================
$Score = 100
$RiskLevel = "BASSO"
$TableRows = ""
$Date = Get-Date -Format "dd/MM/yyyy"
$RemediationList = ""

function Add-Finding {
    param ($Area, $Risk, $Message, $PointsLost, $Remediation)
    
    # Pulizia brutale dei caratteri speciali prima che tocchino il Markdown
    $CleanMessage = $Message.Replace("\", " / ")
    # Fix per le lettere accentate che arrivano sporche dal terminale
    $CleanMessage = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($CleanMessage))
    
    $script:TableRows += "| **${Area}** | **${Risk}** | ${CleanMessage} `n"
    $script:Score -= $PointsLost
    
    if ($Remediation -and ($script:RemediationList -notlike "*$Remediation*")) {
        $script:RemediationList += "* [ ] **${Area}**: ${Remediation}`n"
    }
    Write-Host "[FAIL] ${Area}: ${Message}" -ForegroundColor Red
}

Write-Host "`n[*] Avvio Analisi Avanzata..." -ForegroundColor Cyan

# --- TEST 1: RDP & FIREWALL ---
Write-Host "[*] Verifica RDP e Policy di Rete..." -NoNewline
try {
    $RdpRegistry = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction Stop
    if ($RdpRegistry.fDenyTSConnections -eq 0) {
        $RdpRules = Get-NetFirewallRule -Enabled True | Where-Object { $_.DisplayName -like "*Remote Desktop*" -or $_.Name -like "*RemoteDesktop*" } -ErrorAction SilentlyContinue
        if ($null -ne $RdpRules) {
            Add-Finding -Area "Network" -Risk "MEDIO" -Message "RDP abilitato e permesso nel Firewall." -PointsLost 10 `
                        -Remediation "Disabilitare l'RDP se non necessario o limitare l'accesso tramite VPN/Tailscale e Firewall."
            Write-Host " [ATTENZIONE]" -ForegroundColor Yellow
        } else { Write-Host " [OK - Firewall Chiuso]" -ForegroundColor Green }
    } else { Write-Host " [OK - Disabilitato]" -ForegroundColor Green }
} catch {
    Write-Host " [ERRORE]" -ForegroundColor Red
    Add-Finding -Area "Network" -Risk "INFO" -Message "Impossibile analizzare RDP." -PointsLost 0
}

# --- TEST 2: BITLOCKER DEEP CHECK ---
Write-Host "[*] Verifica Cifratura Disco..." -NoNewline
try {
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        $BitLocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
        if ($BitLocker.VolumeStatus -ne "FullyEncrypted") {
            Add-Finding -Area "Sicurezza Disco" -Risk "CRITICO" -Message "Disco C: non interamente cifrato." -PointsLost 30 `
                        -Remediation "Attivare BitLocker su tutti i volumi di sistema per proteggere i dati a riposo."
            Write-Host " [NON CIFRATO]" -ForegroundColor Red
        } elseif ($BitLocker.ProtectionStatus -ne "On") {
            Add-Finding -Area "Sicurezza Disco" -Risk "ALTO" -Message "Cifratura presente ma protezione SOSPESA." -PointsLost 20 `
                        -Remediation "Ripristinare la protezione di BitLocker (Resume-BitLocker) per garantire la sicurezza del volume."
            Write-Host " [SOSPESA]" -ForegroundColor Yellow
        } else { Write-Host " [OK]" -ForegroundColor Green }
    } else { throw "Modulo non trovato." }
} catch {
    Write-Host " [SKIP]" -ForegroundColor Yellow
    Add-Finding -Area "Sicurezza Disco" -Risk "MEDIO" -Message "Analisi BitLocker fallita." -PointsLost 10 `
                        -Remediation "Verificare la presenza del chip TPM e abilitare la cifratura del disco."
}

# --- TEST 3: WINDOWS UPDATE ---
Write-Host "[*] Verifica Aggiornamenti..." -NoNewline
try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
    $Count = $SearchResult.Updates.Count
    if ($Count -gt 0) {
        Add-Finding -Area "Patching" -Risk "MEDIO" -Message "Trovati $Count aggiornamenti di sicurezza pendenti." -PointsLost ($Count * 2) `
                    -Remediation "Installare immediatamente gli aggiornamenti di Windows pendenti per chiudere le vulnerabilità note."
        Write-Host " [PENDENTI: $Count]" -ForegroundColor Yellow
    } else { Write-Host " [OK]" -ForegroundColor Green }
} catch {
    Write-Host " [ERRORE]" -ForegroundColor Red
    Add-Finding -Area "Patching" -Risk "INFO" -Message "Impossibile verificare update." -PointsLost 0
}

# --- TEST 4: PRIVILEGI UTENTE (Local Admins) ---
Write-Host "[*] Analisi Privilegi Utenti Locali..." -NoNewline
try {
    $Admins = Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.PrincipalSource -ne "Unknown" }
    $HumanAdmins = $Admins | Where-Object { $_.Name -notmatch "Administrator|Domain Admins" }
    
    if ($HumanAdmins.Count -gt 1) {
        $AdminNames = $HumanAdmins.Name -join ", "
        Add-Finding -Area "Privilegi" -Risk "ALTO" -Message "Troppi admin locali: ($AdminNames)." -PointsLost 25 `
                    -Remediation "Ridurre il numero di utenti con privilegi amministrativi. Usare un account standard per le attività quotidiane."
        Write-Host " [RISCHIO: $($HumanAdmins.Count) Admin]" -ForegroundColor Red
    } else { Write-Host " [OK - Privilegi Minimi]" -ForegroundColor Green }
} catch {
    Write-Host " [ERRORE]" -ForegroundColor Red
    Add-Finding -Area "Privilegi" -Risk "INFO" -Message "Impossibile analizzare gruppi locali." -PointsLost 0
}

# --- TEST 5: SICUREZZA WI-FI (Reti Aperte) ---
Write-Host "[*] Verifica Profili Wi-Fi insicuri..." -NoNewline
try {
    $WifiProfiles = netsh wlan show profiles | Select-String "All User Profile"
    $OpenNetworks = @()
    foreach ($Line in $WifiProfiles) {
        $ProfileName = $Line.ToString().Split(":")[1].Trim()
        if ((netsh wlan show profile name="$ProfileName") -match "Authentication.*Open") { $OpenNetworks += $ProfileName }
    }
    if ($OpenNetworks.Count -gt 0) {
        Add-Finding -Area "Network Wi-Fi" -Risk "MEDIO" -Message "Reti aperte salvate: ($($OpenNetworks -join ', '))." -PointsLost 15 `
                    -Remediation "Rimuovere i profili Wi-Fi aperti o non protetti per evitare attacchi Man-in-the-Middle."
        Write-Host " [RETI APERTE: $($OpenNetworks.Count)]" -ForegroundColor Yellow
    } else { Write-Host " [OK]" -ForegroundColor Green }
} catch { Write-Host " [SKIP]" -ForegroundColor Gray }

# --- TEST 6: INTEGRITÀ SISTEMA (SFC/DISM) ---
Write-Host "[*] Verifica Integrità File di Sistema..." -NoNewline
try {
    $SfcErrors = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue | Where-Object { $_.Message -like "*corrupt*" }
    if ($null -ne $SfcErrors) {
        Add-Finding -Area "Integrità" -Risk "MEDIO" -Message "Corruzioni file di sistema rilevate." -PointsLost 10 `
                    -Remediation "Eseguire i comandi 'sfc /scannow' e 'DISM /Online /Cleanup-Image /RestoreHealth' per riparare il sistema."
        Write-Host " [RILEVATI ERRORI]" -ForegroundColor Yellow
    } else { Write-Host " [OK]" -ForegroundColor Green }
} catch { Write-Host " [ERRORE]" -ForegroundColor Red }

# --- TEST 7: PROCESSI E SOFTWARE AD ALTO RISCHIO ---
Write-Host "[*] Verifica processi e tool potenzialmente pericolosi..." -NoNewline
try {
    # Lista di software che spesso indicano accessi non autorizzati o rischi (es. uTorrent, AnyDesk, Wireshark, nmap)
    $Blacklist = @("AnyDesk", "TeamViewer", "uTorrent", "BitTorrent", "Wireshark", "Advanced IP Scanner")
    $FoundRisks = @()

    foreach ($App in $Blacklist) {
        if (Get-Process -Name "*$App*" -ErrorAction SilentlyContinue) {
            $FoundRisks += $App
        }
    }

    if ($FoundRisks.Count -gt 0) {
        $RiskList = $FoundRisks -join ", "
        Add-Finding -Area "Software" -Risk "ALTO" `
                    -Message "Rilevati processi potenzialmente pericolosi in esecuzione: ($RiskList)." `
                    -PointsLost 20 `
                    -Remediation "Rimuovere i software di telecontrollo non autorizzati o i tool di scansione rete se non necessari all'amministratore."
        Write-Host " [RISCHIO: $($FoundRisks.Count)]" -ForegroundColor Red
    } else {
        Write-Host " [OK]" -ForegroundColor Green
    }
} catch {
    Write-Host " [ERRORE]" -ForegroundColor Red
}

# --- TEST 8: ANALISI SUPERFICIE DI RETE (Listening Ports) ---
Write-Host "[*] Analisi porte di rete in ascolto..." -NoNewline
try {
    # Recuperiamo le connessioni in stato 'Listen' su TCP
    $Ports = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalAddress -ne "127.0.0.1" -and $_.LocalAddress -ne "::1" }
    
    $CriticalPorts = @(135, 139, 445, 3389, 5985, 5986) # Porte sensibili: RPC, NetBIOS, SMB, RDP, WinRM
    $FoundExposures = @()

    foreach ($Conn in $Ports) {
        if ($CriticalPorts -contains $Conn.LocalPort) {
            $Process = Get-Process -Id $Conn.OwningProcess -ErrorAction SilentlyContinue
            $FoundExposures += "Porta $($Conn.LocalPort) ($($Process.Name))"
        }
    }

    if ($FoundExposures.Count -gt 0) {
        $PortList = $FoundExposures -join ", "
        Add-Finding -Area "Network Surface" -Risk "ALTO" `
                    -Message "Rilevate porte critiche aperte su interfacce di rete: ($PortList)." `
                    -PointsLost 25 `
                    -Remediation "Chiudere i servizi non necessari o configurarli affinché restino in ascolto solo su Localhost (127.0.0.1). Verificare le regole del Firewall."
        Write-Host " [RISCHIO: $($FoundExposures.Count) Porte]" -ForegroundColor Red
    } else {
        Write-Host " [OK]" -ForegroundColor Green
    }
} catch {
    Write-Host " [ERRORE]" -ForegroundColor Red
    Add-Finding -Area "Network Surface" -Risk "INFO" -Message "Impossibile analizzare le porte di rete." -PointsLost 0
}

# CALCOLO FINALE
if ($Score -le 50) { $RiskLevel = "CRITICO" } elseif ($Score -le 80) { $RiskLevel = "MEDIO" } else { $RiskLevel = "BASSO" }
if ($Score -lt 0) { $Score = 0 }

# 3. GENERAZIONE REPORT
Write-Host "`n[*] Elaborazione Template..." -ForegroundColor Yellow

# Leggi il template forzando la lettura UTF8
$MDContent = [System.IO.File]::ReadAllLines($TemplatePath, [System.Text.Encoding]::UTF8) -join "`n"

# Sostituzioni tramite la mappa (come abbiamo fatto prima)
$Map = @{
    "{{ClientName}}"      = $ClientName
    "{{Date}}"            = $Date
    "{{Score}}"           = $Score
    "{{RiskLevel}}"       = $RiskLevel
    "{{TableRows}}"       = $TableRows
    "{{RemediationList}}" = $RemediationList
}

$FinalMD = $MDContent
foreach ($Key in $Map.Keys) {
    $FinalMD = $FinalMD.Replace($Key, $Map[$Key])
}

# --- IL FIX DEFINITIVO PER GLI ACCENTI ---
# Scriviamo il file usando una codifica UTF8 pura SENZA BOM.
# Molti editor Windows aggiungono il BOM, XeLaTeX vuole UTF8 "liscio".
$TempMDFile = Join-Path $TempPath "report_temp.md"
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($TempMDFile, $FinalMD, $Utf8NoBomEncoding)
# 4. PANDOC
$OutputPdf = Join-Path $OutputPath "Audit_$($ClientName).pdf"
$LogoFinalPath = (Convert-Path $LogoPath).Replace('\', '/')

Write-Host "[*] Generazione PDF con Pandoc (XeLaTeX)..." -ForegroundColor Green

# Comando Pandoc scritto su riga singola per evitare errori di sintassi
pandoc "$TempMDFile" -o "$OutputPdf" --from markdown --template eisvogel --pdf-engine=xelatex --variable logo="$LogoFinalPath" --variable logo-width=50mm -V geometry:margin=2.5cm --quiet

if (Test-Path $OutputPdf) {
    Write-Host "[SUCCESS] PDF generato: $OutputPdf" -ForegroundColor Green
    Invoke-Item $OutputPdf
} else { Write-Host "[FAIL] Errore nella generazione del PDF." -ForegroundColor Red }