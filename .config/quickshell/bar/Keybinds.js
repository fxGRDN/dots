.pragma library

// Turns `hyprctl binds -j` into cheatsheet columns. Only binds with a description
// are shown; descriptions are "Group | Action" or "Group | Action | KEYS".

var modifiers = [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]];

var keyNames = {
    "mouse:272": "LMB",
    "mouse:273": "RMB",
    "mouse_down": "SCROLL",
    "mouse_up": "SCROLL"
};

function combo(bind) {
    var keys = [];
    for (var i = 0; i < modifiers.length; i++)
        if (bind.modmask & modifiers[i][0]) keys.push(modifiers[i][1]);
    keys.push(keyNames[bind.key] || bind.key.toUpperCase());
    return keys;
}

function parse(json) {
    var groups = [];
    var byName = {};
    var binds = JSON.parse(json);
    for (var i = 0; i < binds.length; i++) {
        var bind = binds[i];
        if (!bind.has_description || bind.submap !== "") continue;
        var parts = bind.description.split("|").map(function (s) { return s.trim(); });
        if (parts.length < 2) parts = ["Other", parts[0]];
        var keys = parts[2] ? parts[2].split(/\s+/) : combo(bind);

        var group = byName[parts[0]];
        if (!group) {
            group = byName[parts[0]] = { name: parts[0], rows: [] };
            groups.push(group);
        }
        var row = group.rows.find(function (r) { return r.action === parts[1]; });
        if (row) row.combos.push(keys);
        else group.rows.push({ action: parts[1], combos: [keys] });
    }
    return groups;
}

// Greedy masonry: each group goes to the currently shortest column.
function columns(groups, count) {
    var cols = [];
    var heights = [];
    for (var i = 0; i < count; i++) { cols.push([]); heights.push(0); }
    for (var g = 0; g < groups.length; g++) {
        var shortest = heights.indexOf(Math.min.apply(null, heights));
        cols[shortest].push(groups[g]);
        heights[shortest] += groups[g].rows.length + 2;
    }
    return cols.filter(function (c) { return c.length > 0; });
}
