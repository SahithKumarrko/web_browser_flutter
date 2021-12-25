const AbstractProvider = class {
    constructor() {
        this.ids = {}, this.videos = [], this.setBadge()
    }
    run() {
        setInterval((() => this.search()), 1e3)
    }
    search() {}
    addVideo(t, e) {
        this.ids[t] = !0, this.getVideoData(t, (i => i.variants.length ? void this.getAllSizes(i.variants, (n => {
            i.variants = n, this.videos = this.videos.concat(i), this.setBadge(), this.renderBtn(t, e)
        })) : void 0), e)
    }
    getVideoData() {}
    setBadge() {
        chrome.runtime.sendMessage({
            action: "setBadge",
            value: this.videos.length
        })
    }
    renderBtn(t, e) {
        if (!RENDER_BTN_ON_VIDEO) return;
        const i = this.videos.find((e => e.vid === t));
        if (!i) return;
        const n = i.variants.map((t => `\n            <div class="mtz-download-btn-dropdown-item" quality="${t.quality}">${t.quality}</div>\n        `)).join("");
        $(`\n            <button class="mtz-download-btn" vid="${t}">\n                <span>Download</span>\n                <div class="mtz-download-btn-dropdown">${n}</div>\n            </button>\n        `).appendTo(e).on("click", (t => {
            t.stopPropagation(), this.download(t.target)
        }))
    }
    download(t) {
        const e = t.closest("[vid]").getAttribute("vid"),
            i = t.getAttribute("quality");
        if (!i) return;
        const n = this.videos.find((t => t.vid === e)),
            s = n.variants.find((t => t.quality === i)),
            o = {
                title: n.title,
                url: s.url
            };
        n && s && chrome.runtime.sendMessage({
            action: "downloadVideo",
            data: o
        })
    }
    getAllSizes(t, e) {
        if (!GET_FILE_SIZE) return e(t);
        const i = t.map((t => this.getFileSize(t.url)));
        Promise.all(i).then((i => {
            t.forEach(((e, n) => t[n].size = i[n])), e(t)
        }))
    }
    getFileSize(t) {
        return new Promise((e => {
            const i = new XMLHttpRequest;
            i.open("HEAD", t, !0), i.onload = () => {
                if (200 === i.status) {
                    const t = +i.getResponseHeader("Content-Length");
                    return e(t)
                }
                e(0)
            }, i.onerror = () => e(0), i.send()
        }))
    }
    getCookie(t) {
        var e = ("; " + document.cookie).split("; " + t + "=");
        if (2 == e.length) return e.pop().split(";").shift()
    }
    betweenStr(t, e, i) {
        if (!e && !i) return t;
        let n = "";
        const s = t.indexOf(e);
        if (-1 === s && (n = ""), s >= 0 && (n = t.substr(s + e.length, t.length)), !i) return n;
        const o = n.indexOf(i);
        return -1 === o && -1 !== s || -1 === o ? "" : (n = n.substr(0, o), n)
    }
};