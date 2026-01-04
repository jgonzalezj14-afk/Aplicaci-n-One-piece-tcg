const express = require("express");
const axios = require("axios");
const cors = require("cors");
require("dotenv").config();

const app = express();
const API_BASE_URL = "https://www.optcgapi.com";
const PORT = process.env.PORT || 6090;

app.use(cors());
app.use(express.json());

const convertToSafeUrl = (originalUrl) => {
    if (!originalUrl) return null;
    const cleanUrl = originalUrl.replace(/^https?:\/\//, '');
    return `https://wsrv.nl/?url=${cleanUrl}&output=webp`;
};

app.get("/random_card", async (req, res) => {
  try {
    const [setsRes, startersRes] = await Promise.allSettled([
        axios.get(`${API_BASE_URL}/api/allSetCards/`),
        axios.get(`${API_BASE_URL}/api/allSTCards/`)
    ]);

    let rawCards = [];
    if (setsRes.status === 'fulfilled') rawCards = rawCards.concat(setsRes.value.data);
    if (startersRes.status === 'fulfilled') rawCards = rawCards.concat(startersRes.value.data);

    if (!rawCards.length) return res.status(404).json({ error: "No hay cartas" });

    const randomIndex = Math.floor(Math.random() * rawCards.length);
    let randomCard = rawCards[randomIndex];

    if (randomCard.card_image && !randomCard.card_image.startsWith("http")) {
        randomCard.card_image = API_BASE_URL + randomCard.card_image;
    }
    
    const isWeb = req.headers['origin'] || req.headers['referer'];

    if (isWeb && randomCard.card_image) {
        randomCard.card_image = convertToSafeUrl(randomCard.card_image);
    }

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

    if (setsRes.status === 'fulfilled') rawCards = rawCards.concat(setsRes.value.data);
    if (startersRes.status === 'fulfilled') rawCards = rawCards.concat(startersRes.value.data);

    const isWeb = req.headers['origin'] || req.headers['referer'];

    rawCards = rawCards.map(card => {
      let originalUrl = card.card_image;
      if (originalUrl && !originalUrl.startsWith("http")) {
        originalUrl = API_BASE_URL + originalUrl;
      }
      
      if (originalUrl) {
          if (isWeb) {
             card.card_image = convertToSafeUrl(originalUrl);
          } else {
             card.card_image = originalUrl;
          }
      }
      return card;
    });

    const groupedMap = new Map();
    rawCards.forEach(card => {
        if (!card.card_set_id) return;
        const id = card.card_set_id;
        if (!groupedMap.has(id)) groupedMap.set(id, []); 
        groupedMap.get(id).push(card);
    });

    let cards = [];
    groupedMap.forEach((versions) => {
        versions.sort((a, b) => {
            const aP = (a.card_image||"").includes("_p") || (a.card_name||"").toLowerCase().includes("parallel");
            const bP = (b.card_image||"").includes("_p") || (b.card_name||"").toLowerCase().includes("parallel");
            if (aP && !bP) return 1;
            if (!aP && bP) return -1;
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
    if (name) cards = cards.filter(c => c.card_name?.toLowerCase().includes(name.trim().toLowerCase()));
    if (cost && cost !== 'All') cards = cards.filter(c => c.card_cost?.toString() === cost.toString());
    if (color && color !== 'All') cards = cards.filter(c => c.card_color?.toLowerCase() === color.toLowerCase());
    if (type && type !== 'All') cards = cards.filter(c => c.card_type?.toLowerCase() === type.toLowerCase());
    if (set && set !== 'All' && set !== 'All Sets') {
      const s = set.toUpperCase().trim().replace('-', '');
      cards = cards.filter(c => {
         if (!c.card_set_id) return false;
         const cid = c.card_set_id.toUpperCase();
         if (set.toUpperCase() === 'P') return cid.startsWith('P-') || (cid.startsWith('P') && !cid.startsWith('PRB'));
         return cid.replace('-', '').startsWith(s);
      });
    }

    cards.sort((a, b) => (a.card_set_id || "").localeCompare(b.card_set_id || ""));

    const totalPages = Math.ceil(cards.length / limitNum);
    const paginatedCards = cards.slice((pageNum - 1) * limitNum, pageNum * limitNum);

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