.pragma library

// Freedesktop main categories in priority order; an app lands in the first one it matches.
var categories = [
    { name: "GAMES", match: ["Game"] },
    { name: "DEV", match: ["Development"] },
    { name: "GRAPHICS", match: ["Graphics"] },
    { name: "MEDIA", match: ["AudioVideo", "Audio", "Video"] },
    { name: "OFFICE", match: ["Office"] },
    { name: "INTERNET", match: ["Network"] },
    { name: "SETTINGS", match: ["Settings"] },
    { name: "SYSTEM", match: ["System"] },
    { name: "UTILITIES", match: ["Utility"] }
];

var otherCategory = "OTHER";

function categoryOf(entry) {
    const own = Array.from(entry.categories || []);
    for (const category of categories) {
        if (category.match.some(c => own.includes(c))) return category.name;
    }
    return otherCategory;
}

function byUsageThenName(usage) {
    return (a, b) => (usage[b.id] || 0) - (usage[a.id] || 0) || a.name.localeCompare(b.name);
}

// Higher is better; -1 means no match.
function score(query, entry, usage) {
    const q = query.toLowerCase();
    const name = entry.name.toLowerCase();
    const bonus = Math.min(usage[entry.id] || 0, 50);

    if (name === q) return 1000 + bonus;
    if (name.startsWith(q)) return 800 + bonus;
    if (name.split(/[\s\-_.]+/).some(word => word.startsWith(q))) return 600 + bonus;
    const index = name.indexOf(q);
    if (index >= 0) return 400 - index + bonus;

    const extra = [entry.genericName, entry.comment, entry.id, ...Array.from(entry.keywords || [])]
        .filter(Boolean).join(" ").toLowerCase();
    if (extra.includes(q)) return 200 + bonus;

    // Subsequence match on the name, penalised by gaps.
    let position = 0;
    let gaps = 0;
    for (const char of q) {
        const found = name.indexOf(char, position);
        if (found < 0) return -1;
        gaps += found - position;
        position = found + 1;
    }
    return Math.max(1, 100 - gaps) + bonus;
}
