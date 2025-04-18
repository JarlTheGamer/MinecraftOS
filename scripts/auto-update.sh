#!/bin/bash

# MinecraftOS Auto-Update Script
# Dit script controleert op updates in de GitHub repository en past deze toe

# Configuratie
GITHUB_REPO="JarlTheGamer/MinecraftOS"
INSTALL_DIR="/opt/minecraft"
WEB_DIR="${INSTALL_DIR}/web"
BACKUP_DIR="${INSTALL_DIR}/backups/system"
LOG_FILE="${INSTALL_DIR}/logs/update.log"
CURRENT_VERSION_FILE="${INSTALL_DIR}/.version"

# Zorg ervoor dat de nodige mappen bestaan
mkdir -p "${BACKUP_DIR}"
mkdir -p "${INSTALL_DIR}/logs"

# Functie voor logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Start auto-update controle"

# Huidige versie ophalen (als deze bestaat)
if [ -f "${CURRENT_VERSION_FILE}" ]; then
  CURRENT_VERSION=$(cat "${CURRENT_VERSION_FILE}")
else
  CURRENT_VERSION="unknown"
  echo "${CURRENT_VERSION}" > "${CURRENT_VERSION_FILE}"
fi

log "Huidige versie: ${CURRENT_VERSION}"

# Controleer of git geïnstalleerd is
if ! command -v git &> /dev/null; then
  log "Git is niet geïnstalleerd. Installeren..."
  apt-get update && apt-get install -y git
fi

# Controleer of de GitHub repository toegankelijk is
if ! git ls-remote "https://github.com/${GITHUB_REPO}" HEAD &> /dev/null; then
  log "Kan geen verbinding maken met GitHub repository. Update geannuleerd."
  exit 1
fi

# Laatste commit hash ophalen van GitHub
LATEST_VERSION=$(git ls-remote "https://github.com/${GITHUB_REPO}" HEAD | awk '{print $1}')

if [ -z "${LATEST_VERSION}" ]; then
  log "Kon de laatste versie niet ophalen. Update geannuleerd."
  exit 1
fi

log "Laatste versie op GitHub: ${LATEST_VERSION}"

# Controleer of er een update beschikbaar is
if [ "${CURRENT_VERSION}" == "${LATEST_VERSION}" ]; then
  log "Je hebt al de nieuwste versie. Geen update nodig."
  exit 0
fi

log "Update beschikbaar! Bijwerken van ${CURRENT_VERSION} naar ${LATEST_VERSION}"

# Maak een backup van de huidige installatie
BACKUP_FILE="${BACKUP_DIR}/minecraftos-backup-$(date '+%Y%m%d-%H%M%S').tar.gz"
log "Backup maken naar ${BACKUP_FILE}..."

tar -czf "${BACKUP_FILE}" -C "${INSTALL_DIR}" web scripts

# Clone of update de repository
if [ -d "${WEB_DIR}/.git" ]; then
  # Repository bestaat al, update het
  log "Repository updaten..."
  cd "${WEB_DIR}"
  git fetch origin
  git reset --hard origin/main
else
  # Repository bestaat niet, clone het
  log "Repository klonen..."
  rm -rf "${WEB_DIR}"
  git clone "https://github.com/${GITHUB_REPO}" "${WEB_DIR}"
fi

# Controleer of de update succesvol was
if [ $? -ne 0 ]; then
  log "Update mislukt. Probeer het later opnieuw."
  exit 1
fi

# Update dependencies en build de applicatie
log "Node.js dependencies updaten..."
cd "${WEB_DIR}"
npm install

log "Applicatie bouwen..."
npm run build

if [ $? -ne 0 ]; then
  log "Bouwen van de applicatie mislukt. Terugdraaien naar vorige versie..."
  # Herstel van backup
  tar -xzf "${BACKUP_FILE}" -C "${INSTALL_DIR}"
  exit 1
fi

# Update scripts
log "Scripts bijwerken..."
if [ -d "${WEB_DIR}/scripts" ]; then
  cp -r "${WEB_DIR}/scripts/"* "${INSTALL_DIR}/scripts/"
  chmod +x "${INSTALL_DIR}/scripts/"*.sh
fi

# Update versie bestand
echo "${LATEST_VERSION}" > "${CURRENT_VERSION_FILE}"

# Herstart services
log "Services herstarten..."
systemctl restart minecraft-web.service

log "Update succesvol afgerond naar versie ${LATEST_VERSION}"

# Stuur een notificatie naar de web interface
echo "{\"version\":\"${LATEST_VERSION}\",\"date\":\"$(date '+%Y-%m-%d %H:%M:%S')\",\"success\":true}" > "${INSTALL_DIR}/.last_update"

exit 0
