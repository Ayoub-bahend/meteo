#!/bin/bash

# Script de test automatique des services Meteo
# Vérifie que tous les services répondent correctement

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Test des Services Meteo${NC}"
echo ""

# Fonction pour tester un endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -e "${YELLOW}Test: ${name}${NC}"
    echo "  URL: ${url}"
    
    response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "$expected_code" ]; then
        echo -e "  ${GREEN}✓ OK (HTTP $http_code)${NC}"
        if command -v jq &> /dev/null; then
            echo "$body" | jq '.' 2>/dev/null || echo "$body"
        else
            echo "$body"
        fi
        echo ""
        return 0
    else
        echo -e "  ${RED}✗ ÉCHEC (HTTP $http_code)${NC}"
        echo "$body"
        echo ""
        return 1
    fi
}

# Tests
success=0
failed=0

# Test Weather Service
if test_endpoint "Weather Service - Paris" "http://localhost:8081/api/weather/Paris"; then
    ((success++))
else
    ((failed++))
fi

# Test Location Service
if test_endpoint "Location Service - Paris" "http://localhost:8082/api/location/Paris"; then
    ((success++))
else
    ((failed++))
fi

# Test Weather Report Service (le plus important - agrégation)
if test_endpoint "Weather Report Service - Paris" "http://localhost:8083/api/report/Paris"; then
    ((success++))
else
    ((failed++))
fi

# Test avec une autre ville
if test_endpoint "Weather Report Service - London" "http://localhost:8083/api/report/London"; then
    ((success++))
else
    ((failed++))
fi

# Résumé
echo -e "${BLUE}=== Résumé des Tests ===${NC}"
echo -e "${GREEN}✓ Succès: $success${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}✗ Échecs: $failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Tous les tests sont passés !${NC}"
    exit 0
fi

