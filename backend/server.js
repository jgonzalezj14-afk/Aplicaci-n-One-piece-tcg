const express = require("express");
const axios = require("axios");
const cors = require("cors");
require("dotenv").config();

const app = express();
const API_BASE_URL = "https://www.optcgapi.com";
const PORT = process.env.PORT || 6090;

app.use(cors({
    origin: "*", 
    methods: ["GET", "POST", "OPTIONS"], 
    allowedHeaders: ["Content-Type", "Authorization", "Access-Control-Allow-Origin"],
    credentials: true
}));

app.use(express.json());

const getDynamicBaseUrl = (req) => {
    return `${req.protocol}://${req.get('host')}`;
};

app.get("/proxy_image", async (req, res) => {
  const imageUrl = req.query.url;
  if (!imageUrl) return res.status(400).send("Falta URL");
  
  try {
    const response = await axios({
      method: 'get',
      url: imageUrl,
      responseType: 'stream'
    });

    res.set("Access-Control-Allow-Origin", "*");
    res.set("Cross-Origin-Resource-Policy", "cross-origin");
    res.set("Access-Control-Allow-Methods", "GET");
    
    if (response.headers['content-type']) {
        res.set("Content-Type", response.headers['content-type']);
    }

    response.data.pipe(res);
  } catch (error) {
    res.status(404).send("Imagen no encontrada");
  }
});

app.get("/random_card", async (req, res) => {
  try {
    const [setsRes, startersRes] = await Promise.allSettled([
        axios.get(`${API_BASE_URL}/api/allSetCards/`),
        axios.get(`${API_BASE_URL}/api/allSTCards/`)
    ]);

    let rawCards = [];
    if (setsRes.status === 'fulfilled') rawCards = rawCards.concat(setsRes.value.data);
    if (startersRes.status === 'fulfilled') rawCards = rawCards.concat(startersRes.value.data);

    if (!rawCards || rawCards.length === 0) {
        return res.status(404).json({ error: "No hay cartas" });
    }

    const randomIndex = Math.floor(Math.random() * rawCards.length);
    let randomCard = rawCards[randomIndex];

    if (randomCard.card_image && !randomCard.card_image.startsWith("http")) {
        randomCard.card_image = API_BASE_URL + randomCard.card_image;
    }
    
    const baseUrl = getDynamicBaseUrl(req);
    randomCard.card_image = `${baseUrl}/proxy_image?url=${encodeURIComponent(randomCard.card_image)}`;

    if (!randomCard.versions) randomCard.versions = [];

    res.json(randomCard);

  } catch (error) {
    res.status(500).json({ error: "Fallo al generar carta" });
  }
});

app.get("/onepiece", async (req, res) => {
  try {
    const { name, color, type, set, ids, cost, page = 1, pageSize = 20 } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(pageSize);

    let rawCards = [];
    
    const [setsRes, startersRes] = await Promise.allSettled([
        axios.get(`${API_BASE_URL}/api/allSetCards/`), 
        axios.get(`${API_BASE_URL}/api/allSTCards/`)
    ]);

    if (setsRes.status === 'fulfilled') {
        rawCards = rawCards.concat(setsRes.value.data);
    }

    if (startersRes.status === 'fulfilled') {
        rawCards = rawCards.concat(startersRes.value.data);
    }

    const baseUrl = getDynamicBaseUrl(req);

    rawCards = rawCards.map(card => {
      let originalUrl = card.card_image;
      if (originalUrl && !originalUrl.startsWith("http")) {
        originalUrl = API_BASE_URL + originalUrl;
      }
      
      card.card_image = `${baseUrl}/proxy_image?url=${encodeURIComponent(originalUrl)}`;
      return card;
    });

    const groupedMap = new Map();
    
    rawCards.forEach(card => {
        if (!card.card_set_id) return;
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
            const aName = a.card_name || "";
            const bName = b.card_name || "";
            
            const aIsP = aImg.includes("_p") || aName.toLowerCase().includes("parallel");
            const bIsP = bImg.includes("_p") || bName.toLowerCase().includes("parallel");
            
            if (aIsP && !bIsP) return 1;
            if (!aIsP && bIsP) return -1;
            if (aName.length !== bName.length) {
                return aName.length - bName.length;
            }
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
      const searchTerm = name.trim().toLowerCase();
      cards = cards.filter(c => c.card_name && c.card_name.toLowerCase().includes(searchTerm));
    }

    if (cost && cost !== 'All') {
      cards = cards.filter(c => c.card_cost && c.card_cost.toString() === cost.toString());
    }

    if (color && color !== 'All') {
      cards = cards.filter(c => c.card_color && c.card_color.toLowerCase() === color.toLowerCase());
    }

    if (type && type !== 'All') {
      cards = cards.filter(c => c.card_type && c.card_type.toLowerCase() === type.toLowerCase());
    }

    if (set && set !== 'All' && set !== 'All Sets') {
      const searchSet = set.toUpperCase().trim();
      cards = cards.filter(c => {
        if (!c.card_set_id) return false;
        const cardId = c.card_set_id.toUpperCase();
        if (searchSet === 'P') {
          return cardId.startsWith('P-') || (cardId.startsWith('P') && !cardId.startsWith('PRB'));
        }
        const cleanSet = searchSet.replace('-', ''); 
        const cleanCardId = cardId.replace('-', '');
        return cleanCardId.startsWith(cleanSet);
      });
    }

    cards.sort((a, b) => {
        const idA = a.card_set_id || "";
        const idB = b.card_set_id || "";
        let splitA = idA.split("-");
        let splitB = idB.split("-");
        if (splitA.length === 1) {
             const match = idA.match(/([A-Z]+)(\d+)/);
             if (match) splitA = [match[1], match[2]];
        }
        if (splitB.length === 1) {
             const match = idB.match(/([A-Z]+)(\d+)/);
             if (match) splitB = [match[1], match[2]];
        }
        const setA = splitA[0] || "";
        const setB = splitB[0] || "";
        if (setA !== setB) return setA.localeCompare(setB);
        const numA = parseInt(splitA[1]) || 0;
        const numB = parseInt(splitB[1]) || 0;
        return numA - numB;
    });

    const totalCards = cards.length;
    const totalPages = Math.ceil(totalCards / limitNum);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = pageNum * limitNum;
    
    const paginatedCards = cards.slice(startIndex, endIndex);

    res.json({
      data: paginatedCards,
      currentPage: pageNum,
      totalPages: totalPages
    });

  } catch (error) {
    res.status(500).json({ error: "Fallo en el servidor" });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Servidor iniciado en puerto ${PORT}`);
});