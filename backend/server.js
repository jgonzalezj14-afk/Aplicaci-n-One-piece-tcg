const express = require("express");
const axios = require("axios");
const cors = require("cors");
require("dotenv").config();

const app = express();
const API_BASE_URL = "https://www.optcgapi.com";
const PORT = 6090;

app.use(cors({ origin: "*", methods: ["GET", "POST"], allowedHeaders: ["*"] }));
app.use(express.json());

app.get("/proxy_image", async (req, res) => {
  const imageUrl = req.query.url;
  if (!imageUrl) return res.status(400).send("Falta URL");
  try {
    const response = await axios({
      method: 'get',
      url: imageUrl,
      responseType: 'stream'
    });
    response.data.pipe(res);
  } catch (error) {
    res.status(404).send("Imagen no encontrada");
  }
});

app.get("/random_card", async (req, res) => {
  try {
    const url = `${API_BASE_URL}/api/allSetCards/`; 
    const response = await axios.get(url);
    let rawCards = response.data;

    if (!rawCards || rawCards.length === 0) {
        return res.status(404).json({ error: "No hay cartas" });
    }

    const randomIndex = Math.floor(Math.random() * rawCards.length);
    let randomCard = rawCards[randomIndex];

    if (randomCard.card_image && !randomCard.card_image.startsWith("http")) {
        randomCard.card_image = API_BASE_URL + randomCard.card_image;
    }
    randomCard.card_image = `http://localhost:${PORT}/proxy_image?url=${encodeURIComponent(randomCard.card_image)}`;

    if (!randomCard.versions) randomCard.versions = [];
    if (!randomCard.sub_types) randomCard.sub_types = [];

    console.log(`🎲 Carta Aleatoria: ${randomCard.card_name}`);
    res.json(randomCard);

  } catch (error) {
    console.error("❌ Error Random:", error.message);
    res.status(500).json({ error: "Fallo al generar carta" });
  }
});

app.get("/onepiece", async (req, res) => {
  try {
    const { name, color, type, set, ids, page = 1, pageSize = 20 } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(pageSize);

    const url = `${API_BASE_URL}/api/allSetCards/`; 
    const response = await axios.get(url);
    let rawCards = response.data;

    rawCards = rawCards.map(card => {
      let originalUrl = card.card_image;
      if (originalUrl && !originalUrl.startsWith("http")) {
        originalUrl = API_BASE_URL + originalUrl;
      }
      card.card_image = `http://localhost:${PORT}/proxy_image?url=${encodeURIComponent(originalUrl)}`;
      return card;
    });

    const groupedMap = new Map();
    
    rawCards.forEach(card => {
        const id = card.card_set_id;
        if (!groupedMap.has(id)) {
            groupedMap.set(id, []); 
        }
        groupedMap.get(id).push(card);
    });

    let cards = [];
    groupedMap.forEach((versions) => {
        versions.sort((a, b) => {
            const aImg = a.card_image || "";
            const bImg = b.card_image || "";
            const aIsP = aImg.includes("_p") || (a.card_name && a.card_name.toLowerCase().includes("parallel"));
            const bIsP = bImg.includes("_p") || (b.card_name && b.card_name.toLowerCase().includes("parallel"));
            
            if (aIsP && !bIsP) return 1;
            if (!aIsP && bIsP) return -1;
            return 0;
        });

        const mainCard = versions[0];
        mainCard.versions = versions.slice(1);
        
        cards.push(mainCard);
    });


    if (ids) {
      const idList = ids.split(',').map(id => id.trim());
      cards = cards.filter(c => idList.includes(c.card_set_id));
    }
    
    if (name) {
      const searchTerm = name.trim();
      const isNumber = /^\d+$/.test(searchTerm); 

      if (isNumber) {
        cards = cards.filter(c => c.card_cost && c.card_cost.toString() === searchTerm);
      } else {
        const nameLower = searchTerm.toLowerCase();
        cards = cards.filter(c => c.card_name && c.card_name.toLowerCase().includes(nameLower));
      }
    }

    if (color && color !== 'All') {
      cards = cards.filter(c => c.card_color && c.card_color.toLowerCase() === color.toLowerCase());
    }

    
    if (type && type !== 'All') {
      cards = cards.filter(c => c.card_type && c.card_type.toLowerCase() === type.toLowerCase());
    }

    if (set && set !== 'All') {
      const cleanSet = set.replace('-', ''); 
      cards = cards.filter(c => c.card_set_id && c.card_set_id.startsWith(cleanSet));
    }

    const totalCards = cards.length;
    const totalPages = Math.ceil(totalCards / limitNum);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = pageNum * limitNum;
    
    const paginatedCards = cards.slice(startIndex, endIndex);

    console.log(`Pág ${pageNum}/${totalPages}: Enviando ${paginatedCards.length} cartas.`);
    
    res.json({
      data: paginatedCards,
      currentPage: pageNum,
      totalPages: totalPages
    });

  } catch (error) {
    console.error("Error:", error.message);
    res.status(500).json({ error: "Fallo en el servidor" });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor LISTO en: http://localhost:${PORT}/onepiece`);
});