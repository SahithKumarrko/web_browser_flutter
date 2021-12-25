String.prototype.htmlSymDecode = function() {
    const e = document.createElement("div");
    return e.innerHTML = this, e.innerText
}, Number.prototype.formatSize = function() {
    let e = this,
        t = "B";
    return e > 1024 && (e = Math.round(e / 1024 * 100) / 100, t = "KB"), e > 1024 && (e = Math.round(e / 1024 * 100) / 100, t = "MB"), e > 1024 && (e = Math.round(e / 1024 * 100) / 100, t = "GB"), e + t
}, String.prototype.clearFilename = function() {
    return this.htmlSymDecode().replace(/^\./, "_").replace(/\t/g, " ").replace(/[\u0000-\u001f\u007f-\u009f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200b-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g, "").replace(/&quot;/g, "").replace(/&amp;/g, "&").replace(/↵/g, " ").replace(/[\\/:*?<>|~"]/g, "_").slice(0, 100)
};