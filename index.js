const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const BASE_URL = 'https://merolagani.com';

const fetchPage = async (url) => {
    const response = await axios.get(url, {
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        },
        timeout: 30000
    });
    return cheerio.load(response.data);
};

const parseTable = ($table, rowParser) => {
    const data = [];
    $table.find('tbody tr').each((i, row) => {
        const $cells = $(row).find('td');
        if ($cells.length > 1) {
            const item = rowParser($cells);
            if (item) data.push(item);
        }
    });
    return data;
};

const cleanText = (text) => text ? text.trim().replace(/[\n\r]+|[\s]{2,}/g, ' ') : '';

const parseNumber = (text) => {
    const num = parseFloat(text.replace(/,/g, '').replace(/[^0-9.-]/g, ''));
    return isNaN(num) ? 0 : num;
};

const parseDate = (text) => {
    const cleaned = cleanText(text);
    const match = cleaned.match(/(\d{4}[-\/]\d{2}[-\/]\d{2})|(\d{2}[-\/]\d{2}[-\/]\d{4})/);
    return match ? match[0] : cleaned;
};

// IPO Data
app.get('/api/ipo', async (req, res) => {
    try {
        const $ = await fetchPage(`${BASE_URL}/LatestPublicIssue.aspx`);
        
        const ipoData = parseTable($('#ctl00_ContentPlaceHolder1_GridView1'), ($cells) => {
            const symbol = cleanText($cells.eq(0).text());
            if (!symbol || symbol === 'Symbol' || symbol.includes('---')) return null;
            
            return {
                symbol: symbol,
                companyName: cleanText($cells.eq(1).text()),
                type: cleanText($cells.eq(2).text()) || 'IPO',
                sharePrice: parseNumber($cells.eq(3).text()),
                totalUnits: parseNumber($cells.eq(4).text()),
                openDate: parseDate($cells.eq(5).text()),
                closeDate: parseDate($cells.eq(6).text()),
                status: cleanText($cells.eq(7).text()) || 'Open',
                sector: cleanText($cells.eq(8).text())
            };
        });

        res.json(ipoData);
    } catch (error) {
        console.error('IPO Error:', error.message);
        res.status(500).json({ error: 'Failed to fetch IPO data', details: error.message });
    }
});

// Right Share Data
app.get('/api/right-share', async (req, res) => {
    try {
        const $ = await fetchPage(`${BASE_URL}/RightShare.aspx`);
        
        const rightShareData = parseTable($('#ctl00_ContentPlaceHolder1_GridView1'), ($cells) => {
            const symbol = cleanText($cells.eq(0).text());
            if (!symbol || symbol === 'Symbol' || symbol.includes('---')) return null;
            
            return {
                symbol: symbol,
                companyName: cleanText($cells.eq(1).text()),
                ratio: cleanText($cells.eq(2).text()),
                sharePrice: parseNumber($cells.eq(3).text()),
                openDate: parseDate($cells.eq(4).text()),
                closeDate: parseDate($cells.eq(5).text()),
                status: cleanText($cells.eq(6).text()) || 'Open',
                sector: cleanText($cells.eq(7).text())
            };
        });

        res.json(rightShareData);
    } catch (error) {
        console.error('Right Share Error:', error.message);
        res.status(500).json({ error: 'Failed to fetch right share data', details: error.message });
    }
});

// Bonus Data
app.get('/api/bonus', async (req, res) => {
    try {
        const $ = await fetchPage(`${BASE_URL}/Bonus.aspx`);
        
        const bonusData = parseTable($('#ctl00_ContentPlaceHolder1_GridView1'), ($cells) => {
            const symbol = cleanText($cells.eq(0).text());
            if (!symbol || symbol === 'Symbol' || symbol.includes('---')) return null;
            
            const bonusText = cleanText($cells.eq(2).text());
            const cashText = cleanText($cells.eq(3).text());
            
            let bonusPercent = 0;
            let isCreditBonus = false;
            
            const bonusMatch = bonusText.match(/([\d.]+)%/);
            if (bonusMatch) {
                bonusPercent = parseFloat(bonusMatch[1]);
            } else if (bonusText.toLowerCase().includes('credit')) {
                isCreditBonus = true;
                const creditMatch = bonusText.match(/([\d.]+)/);
                if (creditMatch) bonusPercent = parseFloat(creditMatch[1]);
            }
            
            return {
                symbol: symbol,
                companyName: cleanText($cells.eq(1).text()),
                bonus: bonusPercent,
                cash: parseNumber(cashText),
                bookCloseDate: parseDate($cells.eq(4).text()),
                status: cleanText($cells.eq(5).text()) || 'Announced',
                fiscalYear: cleanText($cells.eq(6).text()),
                sector: cleanText($cells.eq(7).text()),
                isCreditBonus: isCreditBonus
            };
        });

        res.json(bonusData);
    } catch (error) {
        console.error('Bonus Error:', error.message);
        res.status(500).json({ error: 'Failed to fetch bonus data', details: error.message });
    }
});

// Promoter Share Data  
app.get('/api/promoter', async (req, res) => {
    try {
        const $ = await fetchPage(`${BASE_URL}/PromoterShare.aspx`);
        
        const promoterData = parseTable($('#ctl00_ContentPlaceHolder1_GridView1'), ($cells) => {
            const symbol = cleanText($cells.eq(0).text());
            if (!symbol || symbol === 'Symbol' || symbol.includes('---')) return null;
            
            const statusText = cleanText($cells.eq(4).text());
            let status = 'Locked';
            let daysLeft = '—';
            
            if (statusText.toLowerCase().includes('unlocked')) {
                status = 'Unlocked';
            } else if (statusText.toLowerCase().includes('on sale')) {
                status = 'On Sale';
                daysLeft = 'Now';
            } else if (statusText.toLowerCase().includes('unlock')) {
                status = 'Unlocking Soon';
            }
            
            return {
                symbol: symbol,
                companyName: cleanText($cells.eq(1).text()),
                units: parseNumber($cells.eq(2).text()),
                unlockDate: parseDate($cells.eq(3).text()),
                price: parseNumber($cells.eq(4).text()),
                status: status,
                daysLeft: daysLeft,
                sector: cleanText($cells.eq(5).text())
            };
        });

        res.json(promoterData);
    } catch (error) {
        console.error('Promoter Error:', error.message);
        res.status(500).json({ error: 'Failed to fetch promoter share data', details: error.message });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// All data in one endpoint
app.get('/api/all', async (req, res) => {
    try {
        const [ipo, rightShare, bonus, promoter] = await Promise.all([
            axios.get(`${BASE_URL}/LatestPublicIssue.aspx`).then(r => cheerio.load(r.data)),
            axios.get(`${BASE_URL}/RightShare.aspx`).then(r => cheerio.load(r.data)),
            axios.get(`${BASE_URL}/Bonus.aspx`).then(r => cheerio.load(r.data)),
            axios.get(`${BASE_URL}/PromoterShare.aspx`).then(r => cheerio.load(r.data))
        ]);
        
        const parseTable = ($, tableId, rowParser) => {
            const data = [];
            $(tableId).find('tbody tr').each((i, row) => {
                const $cells = $(row).find('td');
                if ($cells.length > 1) {
                    const item = rowParser($cells);
                    if (item) data.push(item);
                }
            });
            return data;
        };
        
        res.json({
            ipo: parseTable(ipo, '#ctl00_ContentPlaceHolder1_GridView1', ($cells) => {
                const symbol = cleanText($cells.eq(0).text());
                if (!symbol || symbol === 'Symbol') return null;
                return {
                    symbol, companyName: cleanText($cells.eq(1).text()),
                    type: cleanText($cells.eq(2).text()), sharePrice: parseNumber($cells.eq(3).text()),
                    totalUnits: parseNumber($cells.eq(4).text()), openDate: parseDate($cells.eq(5).text()),
                    closeDate: parseDate($cells.eq(6).text()), status: cleanText($cells.eq(7).text()),
                    sector: cleanText($cells.eq(8).text())
                };
            }),
            rightShare: parseTable(rightShare, '#ctl00_ContentPlaceHolder1_GridView1', ($cells) => {
                const symbol = cleanText($cells.eq(0).text());
                if (!symbol || symbol === 'Symbol') return null;
                return {
                    symbol, companyName: cleanText($cells.eq(1).text()),
                    ratio: cleanText($cells.eq(2).text()), sharePrice: parseNumber($cells.eq(3).text()),
                    openDate: parseDate($cells.eq(4).text()), closeDate: parseDate($cells.eq(5).text()),
                    status: cleanText($cells.eq(6).text()), sector: cleanText($cells.eq(7).text())
                };
            }),
            bonus: parseTable(bonus, '#ctl00_ContentPlaceHolder1_GridView1', ($cells) => {
                const symbol = cleanText($cells.eq(0).text());
                if (!symbol || symbol === 'Symbol') return null;
                return {
                    symbol, companyName: cleanText($cells.eq(1).text()),
                    bonus: parseNumber($cells.eq(2).text()), cash: parseNumber($cells.eq(3).text()),
                    bookCloseDate: parseDate($cells.eq(4).text()), status: cleanText($cells.eq(5).text()),
                    fiscalYear: cleanText($cells.eq(6).text()), sector: cleanText($cells.eq(7).text())
                };
            }),
            promoter: parseTable(promoter, '#ctl00_ContentPlaceHolder1_GridView1', ($cells) => {
                const symbol = cleanText($cells.eq(0).text());
                if (!symbol || symbol === 'Symbol') return null;
                return {
                    symbol, companyName: cleanText($cells.eq(1).text()),
                    units: parseNumber($cells.eq(2).text()), unlockDate: parseDate($cells.eq(3).text()),
                    price: parseNumber($cells.eq(4).text()), sector: cleanText($cells.eq(5).text())
                };
            })
        });
    } catch (error) {
        console.error('All Data Error:', error.message);
        res.status(500).json({ error: 'Failed to fetch all data', details: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`NEPSE API server running on port ${PORT}`);
});