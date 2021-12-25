const DMProvider = class extends AbstractProvider {
    search() {
        const t = this.getIdFromLocation();
        t && !this.ids[t] && this.addVideo(t, ".dmp_Player.np_Player")
    }
    getIdFromLocation() {
        return /^\/\w{0,2}$/.test(location.pathname) ? null : location.pathname.replace("/video/", "")
    }
    validationId(t) {
        return /[\w\d]{1,9}/i.test(t)
    }
    parseMpegString(t) {
        return t.split("\n").slice(1, -1).reduce(((t, e, i, s) => i % 2 != 0 ? t : [...t, {
            props: e,
            stream: s[i + 1]
        }]), [])
    }
    mapKeys(t, e) {
        return {
            formatId: e,
            formatName: "mp4",
            formatNote: `${t.NAME}p`,
            formatWidth: Number(t.NAME),
            formatType: "video",
            formatCodec: t.CODECS,
            url: t["PROGRESSIVE-URI"]
        }
    }
    parseMPEGData(t, e) {
        const {
            props: i
        } = t, s = i.match(/[A-Z\-_]+=/g);
        if (!s) return;
        const r = s.map((t => t.replace("=", ""))).reduce(((t, e, s, r) => {
            const o = r[s + 1],
                a = this.betweenStr(i, `${e}=`, o ? `,${o}` : void 0).replace(/\"/g, "");
            return a ? {
                ...t,
                [e]: a
            } : t
        }), {});
        return this.mapKeys(r, e)
    }
    getFormats(t = {}) {
        return new Promise(((e, i) => {
            const {
                qualities: s = {}
            } = t, {
                auto: r
            } = s;
            r && 0 !== r.length || e([]);
            const o = r[0];
            fetch(o.url).then((t => t.text())).then((t => {
                t || e([]);
                const i = this.parseMpegString(t).map(((t, e) => this.parseMPEGData(t, e)));
                e(this.sortFormatsByWidth(this.filterUnique(i)))
            }))
        }))
    }
    decoder(t) {
        const e = t.split(","),
            i = "qwertyuiopasdf:ghjklzxcvbnm.1234567890/".split("");
        return e.map((t => i[+t])).join("")
    }
    getVideoData(t, e) {
        if (!this.validationId(t)) throw Error("No valid id");
        const i = this.decoder("16,4,4,9,11,14,38,38,1,1,1,27,12,10,7,19,5,26,8,4,7,8,25,27,22,8,26,38,9,19,10,5,2,3,38,26,2,4,10,12,10,4,10,38,23,7,12,2,8,38"),
            s = new URL(i);
        s.pathname = s.pathname + t, s.searchParams.append("app", "com.dailymotion.neon"), s.searchParams.append("locale", "en"), s.searchParams.append("client_type", "website");
        fetch(s.href).then((t => t.text())).then((t => {
            if (!t) throw new Error("There are no metadata!");
            return JSON.parse(t)
        })).then((t => Promise.all([{
            id: t.view_id,
            title: t.title
        }, this.getFormats(t)]))).then((t => {
            const i = t[1],
                s = [];
            for (let t = 0; t < i.length; t++) s.push({
                quality: i[t].formatNote.split("@")[0].match(/\d+/)[0],
                url: i[t].url
            });
            s.sort(((t, e) => t.quality < e.quality ? 1 : -1));
            const r = {
                vid: t[0].id,
                title: t[0].title,
                provider: "dm",
                variants: s
            };
            e(r)
        })).catch((t => {}))
    }
    filterUnique(t) {
        return t.reduce(((t, e) => -1 !== t.findIndex((t => t.formatNote === e.formatNote)) ? t : [...t, e]), [])
    }
    sortFormatsByWidth(t) {
        return t.sort(((t, e) => e.formatWidth >= t.formatWidth ? 1 : -1))
    }
},
FBProvider = class extends AbstractProvider {
    constructor() {
        super(), this.async_get_token = $('script:contains("async_get_token")').text().split('async_get_token":"').pop().split('"')[0], this.user_id = $('script:contains("async_get_token")').text().split('USER_ID":"').pop().split('"')[0], this.INIT_CLASS = "mb-pnnclahpifbjkboanbjecjoaoelleoep"
    }
    search() {
        window.location.href !== this.location && (this.videos = [], this.setBadge(), $("*").removeClass(INIT_CLASS), this.location = window.location.href), $('a[href*="/videos/"]').not("." + this.INIT_CLASS).each(((t, e) => {
            var i = $(e);
            i.addClass(this.INIT_CLASS);
            var s = i.attr("href"),
                r = this.GetVideoIdFromURL(s);
            "number" == typeof r && "string" == typeof s && this.GetVideosFromURL(s, r).catch((t => {
                this.getVideoFromPost(r)
            }))
        }))
    }
    GetVideoIdFromURL(t) {
        var e = null;
        try {
            var i = this.parseURL(t),
                s = i.query,
                r = i.path,
                o = this.ParseQuery(s);
            if (r.indexOf("ajax/sharer") >= 0) e = o.id;
            else if (r.indexOf("/videos/") >= 0) {
                var a = r.split("/").filter((t => t.length > 0));
                e = a[a.length - 1]
            } else r.indexOf("/watch/") >= 0 ? e = o.v : r.indexOf("permalink.php") >= 0 && (e = o.story_fbid);
            if (!e) throw new Error("Id not found");
            e = parseInt(e)
        } catch (t) {
            return null
        }
        return e
    }
    decoder(t) {
        const e = t.split(","),
            i = "qwertyuiopasdf:ghjklzx_cvbnm.1234567890/?=".split("");
        return e.map((t => i[+t])).join("")
    }
    getVideoFromPost(t) {
        this.Fetch(`this.decoder(\n      "16,4,4,9,11,14,39,39,27,28,13,10,23,2,25,8,8,18,28,23,8,27,39,11,4,8,3,5,28,9,16,9,40,11,4,8,3,5,22,13,25,7,12"\n    )=${t}&id=${this.user_id}`, !1).then((e => {
            let i = this.findOnceMatch(e, /video&quot;,&quot;src&quot;:\s*&quot;([^\"]+)&quot;/);
            if (i) {
                const s = i[0].replaceAll("\\", "").replaceAll("&amp;", "&").split("&quot;")[0],
                    r = $("<div />", {
                        html: e.split("<strong>")[1].split("</strong>")[0] + " - " + e.split("<abbr>")[1].split("</abbr>")[0]
                    }).text();
                this.pushVideo({
                    vid: t,
                    variants: [{
                        url: s,
                        quality: "240"
                    }],
                    title: r
                })
            }
        }))
    }
    GetVideosFromURL(t, e) {
        if (null !== e) return t = this.decoder("16,4,4,9,11,14,39,39,1,1,1,28,13,10,23,2,25,8,8,18,28,23,8,27,39,24,7,12,2,8,28,9,16,9,40,24,41") + e, t = this.decoder("16,4,4,9,11,14,39,39,1,1,1,28,13,10,23,2,25,8,8,18,28,23,8,27,39,9,19,6,15,7,26,11,39,24,7,12,2,8,28,9,16,9,40") + $.param({
            href: t
        }), this.Fetch(t, !1).then((i => {
            var s = $("<output>").append(i),
                r = ($("title", s).text(), $("description", s).attr("content"), this.findMatch(i, /\"ownerName\":\s*\"([^\"]+)\"/gi, "ownerName")),
                o = this.findMatch(i, /\"video_id\":\s*\"([^\"]+)\"/gi, "video_id"),
                a = this.findMatch(i, /\"sd_src_no_ratelimit\":\s*\"([^\"]+)\"/gi, "sd_src_no_ratelimit"),
                n = this.findMatch(i, /\"hd_src_no_ratelimit\":\s*\"([^\"]+)\"/gi, "hd_src_no_ratelimit");
            if (r.length || (r = this.findOnceMatch(i, /ownerName:\s*\"([^\"]+)\"/)), o.length || (o = this.findOnceMatch(i, /video_id:\s*\"([^\"]+)\"/)).length || (o = [e]), a.length || ((a = this.findOnceMatch(i, /sd_src_no_ratelimit:\s*\"([^\"]+)\"/)).length || (a = this.findMatch(i, /\"sd_src\":\s*\"([^\"]+)\"/gi, "sd_src")), a.length || (a = $('meta[property="og:video:url"]', s).attr("content")) && (a = [a])), n.length || (n = this.findOnceMatch(i, /hd_src_no_ratelimit:\s*\"([^\"]+)\"/)).length || (n = this.findMatch(i, /\"hd_src\":\s*\"([^\"]+)\"/gi, "hd_src")), r.length || (r = ["Facebook video"]), !o || !a || o.length < a.length) throw new Error("Not found all ids");
            if (!a.length && !n.length) throw new Error("Not found videos - " + t);
            const d = {
                vid: e,
                variants: [],
                title: s.find("#u_0_c").text() || r[0]
            };
            a[0] && d.variants.push({
                url: a[0],
                quality: "240"
            }), n[0] && d.variants.push({
                url: n[0],
                quality: "720"
            }), this.pushVideo(d)
        }))
    }
    findOnceMatch(t, e) {
        var i = t.match(e);
        return i ? [i[1]] : []
    }
    findMatch(t, e, i) {
        var s = t.match(e);
        return s ? s.filter((function(t, e, i) {
            return i.indexOf(t) === e && t
        })).map((t => JSON.parse("{" + t + "}")[i])) : []
    }
    pushVideo(t) {
        this.ids[t.vid] || (this.ids[t.vid] = !0, this.videos = this.videos.concat(t), t.variants.length > 0 && (this.updateVideos(t), this.setBadge()))
    }
    updateVideos(t) {
        for (let e = 0; e < this.videos.length; e++)
            if (this.videos[e].vid == t.vid) {
                this.videos[e] = {
                    ...t
                };
                break
            }
    }
    hashCode() {
        return Math.random().toString(36).substring(2) + (new Date).getTime().toString(36)
    }
    parseURL(t) {
        for (var e = {
                strictMode: !1,
                key: ["source", "protocol", "authority", "userInfo", "user", "password", "host", "port", "relative", "path", "directory", "file", "query", "anchor"],
                q: {
                    name: "queryKey",
                    parser: /(?:^|&)([^&=]*)=?([^&]*)/g
                },
                parser: {
                    strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*):?([^:@]*))?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
                    loose: /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/\/?)?((?:(([^:@]*):?([^:@]*))?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
                }
            }, i = e.parser[e.strictMode ? "strict" : "loose"].exec(t), s = {}, r = 14; r--;) s[e.key[r]] = i[r] || "";
        var o = {};
        return "" !== s.protocol && (o.scheme = s.protocol), "" !== s.host && (o.host = s.host), "" !== s.port && (o.port = s.port), "" !== s.user && (o.user = s.user), "" !== s.password && (o.pass = s.password), "" !== s.path && (o.path = s.path), "" !== s.query && (o.query = s.query), "" !== s.anchor && (o.fragment = s.anchor), o
    }
    Fetch(t, e) {
        return void 0 === e && (e = !0), new Promise((function(i) {
            chrome.runtime.sendMessage({
                action: "makeXHRrequest",
                url: t,
                config: {},
                responseType: "text"
            }, (t => {
                i(e ? JSON.parse(t) : t)
            }))
        }))
    }
    ParseQuery(t) {
        var e = {},
            i = (t.split("?")[1] || "").split("&");
        for (var s in i)
            if (i.hasOwnProperty(s)) {
                var r = i[s].split("=");
                e[r[0]] = decodeURIComponent(r[1] || "")
            } return e
    }
},
INProvider = class extends AbstractProvider {
    search() {
        $(".v1Nh3.kIKUG").not("." + INIT_CLASS).each(((t, e) => {
            const i = $(e);
            if (i.find(".coreSpriteVideoIconLarge").length) {
                const t = i.children("a").attr("href");
                t && !this.ids[t] && this.addVideo(t, e), i.addClass(INIT_CLASS)
            }
        })), $("article video").not("." + INIT_CLASS).each(((t, e) => {
            const i = $(e),
                s = i.closest("article").find("a.c-Yi7").attr("href");
            s && !this.ids[s] && this.addVideo(s, i.parent()), i.addClass(INIT_CLASS)
        })), $(".y-yJ5.OFkrO").each(((t, e) => {
            const i = $(e),
                s = i[0].baseURI.split("/"),
                r = `/${s[3]}/${s[4]}/${s[5]}/`;
            this.addVideo(r, i.parent())
        })), $("." + INIT_CLASS).length || (this.ids = {}, this.videos = [])
    }
    getVideoData(t, e, i) {
        let s = "https://www.instagram.com" + t;
        s += s.includes("?") ? "&__a=1" : "?__a=1", fetch(s).then((t => t.json())).then((s => {
            if (s.graphql) {
                const i = s.graphql.shortcode_media,
                    r = i.title || i.edge_media_to_caption.edges[0] && i.edge_media_to_caption.edges[0].node && i.edge_media_to_caption.edges[0].node.text || "video",
                    o = i.video_url;
                if (!o) return;
                e({
                    title: r,
                    vid: t,
                    provider: "in",
                    variants: [{
                        url: o,
                        quality: "640"
                    }]
                })
            } else {
                const s = i[0].childNodes[2].baseURI.split("/"),
                    r = `/${s[3]}/${s[4]}/${s[5]}/`;
                e({
                    title: r,
                    vid: t,
                    provider: "in",
                    variants: [{
                        url: i[0].childNodes[2].currentSrc,
                        quality: "640"
                    }]
                })
            }
        }))
    }
},
TWProvider = class extends AbstractProvider {
    constructor() {
        super(), this.oauth2_access_token = "AAAAAAAAAAAAAAAAAAAAAPYXBAAAAAAACLXUNDekMxqa8h%2F40K4moUkGsoc%3DTYfbDKbT3jJPCEVnMYqilB28NHfOPqkca3qaAxGfsyKCs0wRbw"
    }
    getCredentialToken(t) {
        const e = new XMLHttpRequest;
        e.open("GET", TW_CREDENTIAL_TOKEN_URL, !0), e.onload = () => {
            200 === e.status && (TWProvider.ENCODED_TOKEN_CREDENTIAL = e.responseText), t()
        }, e.send()
    }
    getAccessToken(t) {
        const e = this;
        $.ajax({
            type: "POST",
            url: TWProvider.OAUTH2_TOKEN_API_URL,
            headers: {
                Authorization: "Basic " + TWProvider.ENCODED_TOKEN_CREDENTIAL,
                "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
                "x-csrf-token": this.getCookie("ct0")
            },
            data: {
                grant_type: "client_credentials"
            },
            dataType: "json",
            xhrFields: {
                withCredentials: !1
            },
            success: i => {
                e.oauth2_access_token = i.access_token, t && t()
            }
        })
    }
    search() {
        this.oauth2_access_token && $("video").not("." + INIT_CLASS).each(((t, e) => {
            const i = $(e),
                s = i.closest("article"),
                r = this.getTweetId(s),
                o = i.parent();
            r && !this.ids[r] && this.addVideo(r, o), i.addClass(INIT_CLASS)
        }))
    }
    getTweetId(t) {
        return this.getTweetData(t, /(?:https:\/\/[A-z.]*\/\w*\/status\/)(\d*)(?:\/?\w*)/g)
    }
    getTweetData(t, e) {
        for (const i of t.find("a").toArray()) {
            const t = e.exec(i.href);
            if (t) return t[1]
        }
    }
    decoder(t) {
        const e = t.split(","),
            i = "qwertyuiopasdf:ghjklzx_cvbnm.1234567890/?=".split("");
        return e.map((t => i[+t])).join("")
    }
    getVideoData(t, e) {
        const i = `${this.decoder("16,4,4,9,11,14,39,39,10,9,7,28,4,1,7,4,4,2,3,28,23,8,27,39,29,28,29,39,11,4,10,4,6,11,2,11,39,11,16,8,1,28,17,11,8,26")}?id=${t}&include_profile_interstitial_type=1&include_blocking=1&include_blocked_by=1&include_followed_by=1&include_want_retweets=1&skip_status=1&cards_platform=Web-12&include_cards=1&include_ext_alt_text=true&include_reply_count=1&tweet_mode=extended&trim_user=false&include_ext_media_color=true`,
            s = {
                headers: {
                    Authorization: "Bearer " + this.oauth2_access_token,
                    "x-csrf-token": this.getCookie("ct0")
                }
            };
        chrome.runtime.sendMessage({
            action: "makeXHRrequest",
            url: i,
            config: s
        }, (i => {
            const s = i.full_text.replace(/(?:https?|ftp):\/\/[\n\S]+/g, ""),
                r = [];
            i.extended_entities.media[0].video_info.variants.filter((t => "video/mp4" === t.content_type)).forEach((t => {
                const e = t.url,
                    i = e.match(/vid\/(.+)\//),
                    s = i && i[1] ? i[1].replace(/^.+x/, "") : "";
                r.push({
                    url: e,
                    quality: s
                }), r.sort(((t, e) => t.quality < e.quality ? 1 : -1))
            }));
            e({
                vid: t,
                title: s,
                provider: "tw",
                variants: r
            })
        }))
    }
};

function decoder(t) {
const e = t.split(","),
    i = "qwertyuiopasdf:ghjklzx_cvbnm.1234567890/?=".split("");
return e.map((t => i[+t])).join("")
}
TWProvider.OAUTH2_TOKEN_API_URL = decoder("16,4,4,9,11,14,39,39,10,9,7,28,4,1,7,4,4,2,3,28,23,8,27,39,8,10,6,4,16,30,39,4,8,18,2,26"), TWProvider.ENCODED_TOKEN_CREDENTIAL = "UEtLaXU5SWpFRVNIVFJVc3Jqbkh1YzBDbDpzb1lMMWZOa3BDTmxLcDVNR0g1QkpGd09KODQwekliWGVWMHc4enFhUXBRTE4yRTJZSA==";
const VKProvider = class extends AbstractProvider {
    search() {
        $("video").not("." + INIT_CLASS).each(((t, e) => {
            const i = this.getVideoIdByHtml(e),
                s = e.closest(".wall_post_cont");
            i && !this.ids[i] && this.addVideo(i, s), e.classList.add(INIT_CLASS)
        })), $(".page_post_thumb_video[data-video]").not("." + INIT_CLASS).each(((t, e) => {
            const i = $(e).attr("data-video"),
                s = e.closest(".wall_post_cont");
            i && !this.ids[i] && this.addVideo(i, s), e.classList.add(INIT_CLASS)
        }))
    }
    getVideoIdByHtml(t) {
        const e = t.closest(".video_box_wrap");
        if (e) {
            const t = e.id.replace("video_box_wrap", "");
            return t || void 0
        }
    }
    getVideoData(t, e) {
        $.get("https://vk.com/al_video.php?act=show_inline&al=1&video=" + t, (i => {
            const s = i.payload[1][3].player.params[0],
                r = [],
                o = s.md_title;
            var a = /^\d+$/;
            for (const t in s)
                if (t.includes("url")) {
                    const e = t.split("").slice(3).join("");
                    a.test(e) && r.push({
                        url: s[t],
                        quality: e
                    })
                } r.sort(((t, e) => +t.quality < +e.quality ? 1 : -1)), e({
                vid: t,
                title: o,
                provider: "vk",
                variants: r
            })
        }))
    }
},
VMProvider = class extends AbstractProvider {
    search() {
        const t = $(".player_container");
        if (!t.length) return;
        const e = t[0].id.replace("clip_", "");
        e && !this.ids[e] && this.addVideo(e, ".player_outro_area")
    }
    decoder(t) {
        const e = t.split(","),
            i = "qwertyuiopasdf:ghjklzx_cvbnm.1234567890/?=&".split("");
        return e.map((t => i[+t])).join("")
    }
    getVideoData(t, e) {
        const i = `${this.decoder("16,4,4,9,11,14,39,39,9,19,10,5,2,3,28,24,7,27,2,8,28,23,8,27")}/video/${t}/config`;
        chrome.runtime.sendMessage({
            action: "makeXHRrequest",
            url: i
        }, (i => {
            const s = $(".-KXLs").text(),
                r = i.request.files.progressive,
                o = [];
            ["1080p", "720p", "480p", "360p", "240p"].forEach((t => {
                const e = r.find((e => e.quality === t));
                e && o.push({
                    url: e.url,
                    quality: t.replace("p", "")
                })
            }));
            e({
                vid: t,
                title: s,
                provider: "vm",
                variants: o
            })
        }))
    }
},
XXProvider = class extends AbstractProvider {
    search() {
        chrome.runtime.sendMessage({
            action: "getTabVideos"
        }, (t => {
            t && t.length !== this.videos.length && (this.videos = t.map((t => ({
                vid: t.vid,
                title: t.title,
                provider: "xx",
                variants: [{
                    url: t.url,
                    quality: "720",
                    size: t.size
                }]
            }))), this.setBadge())
        }))
    }
};