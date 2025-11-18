const express = require("express");
const axios = require("axios");
const cors = require("cors");
require("dotenv").config();

const app = express();
const API_BASE_URL = "https://www.optcgapi.com";

app.use(cors({ origin: "*", methods: ["GET", "POST"], allowedHeaders: ["*"] }));
app.use(express.json());

app.get("/onepiece", async (req, res) => {
  try {
    const { name, color, type, page = 1, pageSize = 20 } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(pageSize);

    const url = `${API_BASE_URL}/api/allSetCards/`; 
    const response = await axios.get(url);
    let rawCards = response.data;

    // 1. LIMPIEZA DE IMÁGENES Y PREPARACIÓN
    rawCards = rawCards.map(card => {
      if (card.card_image && !card.card_image.startsWith("http")) {
        card.card_image = API_BASE_URL + card.card_image;
      }
      return card;
    });

    // 2. AGRUPACIÓN POR ID (La magia)
    // Usamos un Map para unificar cartas con el mismo código (ej: OP01-001)
    const groupedMap = new Map();

    rawCards.forEach(card => {
        const id = card.card_set_id;
        if (!groupedMap.has(id)) {
            // Si es la primera vez que vemos este ID, la guardamos como principal
            // e iniciamos su array de versiones vacía
            groupedMap.set(id, { ...card, versions: [] });
        } else {
            // Si ya existe, añadimos esta carta a las 'versions' de la principal
            groupedMap.get(id).versions.push(card);
        }
    });

    // Convertimos el Map de vuelta a un Array
    let cards = Array.from(groupedMap.values());

    // 3. FILTRADO (Sobre las cartas ya agrupadas)
    if (name) {
      const nameLower = name.toLowerCase();
      cards = cards.filter(c => c.card_name && c.card_name.toLowerCase().includes(nameLower));
    }
    if (color && color !== 'All') {
      cards = cards.filter(c => c.card_color && c.card_color.toLowerCase() === color.toLowerCase());
    }
    if (type && type !== 'All') {
      cards = cards.filter(c => c.card_type && c.card_type.toLowerCase() === type.toLowerCase());
    }

    // 4. PAGINACIÓN
    const totalCards = cards.length;
    const totalPages = Math.ceil(totalCards / limitNum);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = pageNum * limitNum;
    const paginatedCards = cards.slice(startIndex, endIndex);

    console.log(`✅ Pág ${pageNum}/${totalPages}: Enviando ${paginatedCards.length} grupos de cartas.`);
    
    res.json({
      data: paginatedCards,
      currentPage: pageNum,
      totalPages: totalPages
    });

  } catch (error) {
    console.error("❌ Error:", error.message);
    res.status(500).json({ error: "Fallo en el servidor" });
  }
});

const PORT = 6090;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🏴‍☠️ Servidor Agrupador LISTO en: http://localhost:${PORT}/onepiece`);
});