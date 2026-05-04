const axios = require("axios");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const s3 = new S3Client({});
const BUCKET = process.env.BUCKET_NAME;
const SERVER_IPS = process.env.SERVER_IPS.split(",").map(ip => ip.trim()).filter(Boolean);

const TIMEOUT_MS = 3000;
const RETRIES = 2;

async function fetchWithRetry(url, retries = RETRIES) {
    for (let attempt = 1; attempt <= retries + 1; attempt++) {
        try {
            const res = await axios.get(url, { timeout: TIMEOUT_MS });
            return res.data;
        } catch (err) {
            console.error(`Attempt ${attempt} failed for ${url}: ${err.message}`);
            if (attempt === retries + 1) throw err;
            await new Promise(r => setTimeout(r, 500 * attempt));
        }
    }
}

function buildReport(results) {
    const timestamp = new Date().toISOString();
    let total = 0;

    const lines = results.map(r => {
        const count = r?.count ?? 0;
        total += count;
        return `${r.host || r.ip || "unknown"} (${r.ip}): ${count}`;
    });

    return [
        "WHALE REPORT",
        `Generated: ${timestamp}`,
        `Servers polled: ${results.length}`,
        "",
        ...lines,
        "",
        `TOTAL: ${total}`
    ].join("\n");
}

exports.handler = async () => {
    console.log("Lambda report started");
    console.log("Polling servers:", SERVER_IPS);

    const results = await Promise.allSettled(
        SERVER_IPS.map(async ip => {
            const url = `http://${ip}/count/current`;
            const data = await fetchWithRetry(url);
            return { ...data, ip };
        })
    );

    const successful = results
        .filter(r => r.status === "fulfilled")
        .map(r => r.value);

    const failed = results
        .filter(r => r.status === "rejected")
        .map((r, i) => `${SERVER_IPS[i]}: ${r.reason?.message}`);

    if (failed.length > 0) {
        console.warn("Some servers failed:", failed);
    }

    const report = buildReport(successful);
    console.log("Report:\n", report);

    const key = `reports/report-${Date.now()}.txt`;

    await s3.send(new PutObjectCommand({
        Bucket: BUCKET,
        Key: key,
        Body: report,
        ContentType: "text/plain"
    }));

    console.log("Report uploaded:", key);

    return {
        statusCode: 200,
        body: JSON.stringify({ message: "Report generated", key, failed })
    };
};