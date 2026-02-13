---
title: "Infrastructure Security Audit"
subtitle: "Analisi Vulnerabilità e Risk Assessment"
author: "Alessandro Mainardi"
date: "{{Date}}"
lang: "it"
titlepage: true
titlepage-color: "0B1829"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "FFD700"
logo: "C:/MainaAudit/assets/logo.png"
logo-width: 50mm
header-left: "RISERVATO"
header-right: "MainaAudit v2.5"
footer-left: "alexmaina.dev"
footer-right: "Pagina \\thepage"
---

# 1. Executive Summary

**Cliente:** {{ClientName}}
**Data Ispezione:** {{Date}}

In data odierna è stata effettuata un'analisi preliminare dell'infrastruttura IT.
Il punteggio di sicurezza calcolato è:

# **{{Score}} / 100**

Il livello di rischio attuale è classificato come: **{{RiskLevel}}**.

> **Nota dell'Auditor:** L'infrastruttura presenta criticità bloccanti. Si raccomanda di non procedere con operazioni bancarie o trattamento di dati sensibili fino alla risoluzione dei punti indicati nella sezione 2.

---

# 2. Analisi Tecnica Dettagliata

Di seguito l'elenco delle anomalie riscontrate durante la scansione automatizzata.

| Dominio | Livello Rischio | Dettaglio Tecnico |
| :--- | :--- | :--- |
{{TableRows}}

---

# 3. Piano di Rientro (Remediation)

Per mitigare i rischi evidenziati, si consiglia di seguire le seguenti raccomandazioni tecniche prioritarie:

{{RemediationList}}

\vspace{2cm}

\begin{center}
\small Documento generato automaticamente da MainaAudit System.
\end{center}