var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-120899131-1']);
_gaq.push(['_trackPageview', '/hello']);

(function() {
    var ga = document.createElement('script');
    ga.type = 'text/javascript';
    ga.async = true;
    ga.src = 'https://ssl.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(ga, s);
})();

chrome.runtime.onInstalled.addListener(function() {
    chrome.tabs.create({
        url: 'https://bllonet.com/installed/'
    });
});
vd.tabsData = {};
vd.linksToBeDownloaded = {};
vd.savedVideos = {};
var minVideoSize = "1";
vd.isVideoUrl = function (url) {
    let isVideoUrl = false;
    vd.allVideoFormats.some(function (format) {
        if(url.indexOf(format) !=-1) {
            isVideoUrl = true;
            return true;
        }
    });
    return isVideoUrl;
};
vd.requestedUrlInfo = {};

vd.getVideoType = function (responseHeaders) {
    var videoType = null;
    responseHeaders.some(function (responseHeader) {
        if (responseHeader.name.toLowerCase() === 'content-type') {
            vd.allVideoFormats.forEach(function (formatKey) {
                if(responseHeader.value.indexOf(formatKey) !== -1 && !/^audio/i.test(responseHeader.value)) {
                    videoType = formatKey;
                    return true;
                }
            });
            return true;
        }
    });
    return videoType;
};

vd.getNewTabObject = function () {
    return {
        videoLinks : [],
        url : ""
    }
};

vd.getVideoSize = function (videoHeaders) {
    var size = 0;
    videoHeaders.forEach(function (header) {
        if(header.name.toLowerCase() === "content-length") {
            size = parseInt(header.value);
        }
    });
    return size;
};

vd.getVideoDataFromServer = function (url, callback) {
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() {
        if(request.readyState === 2) {
            callback({mime: this.getResponseHeader("Content-Type"), size: this.getResponseHeader("Content-Length")});
            request.abort();
        }
    };
    request.open('Get', url);
    request.send();
};

vd.getFileName = function (str) {
    var regex = /[A-Za-z0-9()_ -]/;
    var escapedStr = "";
    str = Array.from(str);
    str.forEach(function (char) {
        if(regex.test(char)) {
            escapedStr += char;
        }
    });
    return escapedStr;
};

vd.isVideoLinkAlreadyAdded = function (videoLinksData, url) {
    //console.log("URL " + url);
    //console.log(videoLinksData);
    var isAlreadyAdded = false;
    videoLinksData.some(function (videoLinkData) {
        if(videoLinkData.url === url){
            isAlreadyAdded = true;
            return true;
        }
    });
    //console.log("Is already added: "+ isAlreadyAdded);
    return isAlreadyAdded;
};

vd.updateExtensionIcon = function (tabId) {
    var colorize = vd.tabsData[tabId] && vd.tabsData[tabId].videoLinks.length > 0;
    vd.colorizeExtensionIcon(colorize, tabId);
};

vd.addVideoLinkToTabFinalStep = function (tabId, videoLink) {
    //console.log(videoLink);
    //console.log("Trying to add url "+ videoLink.url);
    // console.log(vd.isVideoSizeValid(videoLink, minVideoSize));
    if(!vd.isVideoLinkAlreadyAdded(vd.tabsData[tabId].videoLinks, videoLink.url) && vd.isVideoSizeValid(videoLink, minVideoSize) && vd.isVideoUrl(videoLink.url)) {
        vd.tabsData[tabId].videoLinks.push(videoLink);
        vd.updateExtensionIcon(tabId);
    }
};

vd.addVideoLinkToTab = function (videoLink, tabId, tabUrl) {
    // console.log(videoLink);
    if (!vd.tabsData[tabId]) {
        vd.tabsData[tabId] = vd.getNewTabObject();
    }
    if (tabUrl !== vd.tabsData[tabId].url) {
        vd.tabsData[tabId].videoLinks = [];
        vd.tabsData[tabId].url = tabUrl;
    }
    vd.addVideoLinkToTabFinalStep(tabId, videoLink);
};

vd.inspectNetworkResponseHeaders = function (details) {
    if(vd.linksToBeDownloaded[details.url]) {
        details.responseHeaders.push({name: "Content-Disposition",value: "attachment; filename=\""+vd.linksToBeDownloaded[details.url]+"\""});
        return {
            responseHeaders: details.responseHeaders
        };
    }
    let root_domain = vd.extractRootDomain(details.url);
    let videoType = vd.getVideoType(details.responseHeaders);

    if(root_domain !== 'vimeo.com' && videoType) {
        // console.log("Found video url");
        // console.log(details.url);
        chrome.tabs.query({active: true}, function (tabs) {
            let tab = tabs[0];
            let tabId = tabs[0].id;
            vd.addVideoLinkToTab({
                url: details.url,
                webpage_url: tab.url,
                size: vd.getVideoSize(details.responseHeaders),
                fileName: vd.getFileName(tab.title),
                title: vd.getFileName(tab.title),
                extension: "." + videoType
            }, tabId, tab.url);
        });
    }
    return {
        responseHeaders: details.responseHeaders
    };
};

vd.resetVideoLinks = function (tabId) {
    delete vd.tabsData[tabId];
};

vd.escapeRegExp = function (str) {
    return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
};

vd.addVideoLinks = function (videoLinks, tabId, tabUrl) {
    if(!vd.tabsData[tabId]) {
        vd.tabsData[tabId] = vd.getNewTabObject();
    }
    if(tabUrl !== vd.tabsData[tabId].url) {
        vd.tabsData[tabId].videoLinks = [];
        vd.tabsData[tabId].url = tabUrl;
    }
    videoLinks.forEach(function (videoLink) {
        // console.log(videoLink);
        videoLink.fileName = vd.getFileName(videoLink.fileName) + " - " + videoLink.quality + videoLink.extension;
        if(tabUrl.includes("youtube.com")) {
            videoLink.size = 2048;
        } else {
            vd.getVideoDataFromServer(videoLink.url, function (videoData) {
                videoLink.size = videoData.size;
            });
        }
        vd.addVideoLinkToTab(videoLink, tabId, tabUrl);
    });
};

vd.getVideoLinksForTab = function (tabId) {
    return vd.tabsData[tabId] ? vd.tabsData[tabId] : {};
};

vd.incrementDownloadCount = function () {
    var numberOfDownloads = parseInt(localStorage.getItem('total_number_of_downloads'));
    numberOfDownloads += 1;
    localStorage.setItem('total_number_of_downloads', numberOfDownloads);
    if(numberOfDownloads === 3) {
        if ( confirm("You have downloaded multiple videos with Video Downloader professional. Please share your experience with others and make a review for us.")) {
            chrome.tabs.create({"url":"https://vidow.io/reviews","selected":true}, function(tab){});
        }
    }
    if(numberOfDownloads === 7){
        if ( confirm("You have downloaded multiple videos with Video Downloader professional. Please share your experience with others and make a review for us.")) {
            chrome.tabs.create({"url":"https://vidow.io/reviews","selected":true}, function(tab){});
        }
    }
};

vd.downloadVideoLink = function (url, fileName) {
    // console.log(url+" (Downloading) : " + fileName);
    vd.linksToBeDownloaded[url] = fileName;
    chrome.tabs.query({active: true, currentWindow: true}, function (tabs) {
        chrome.tabs.update(tabs[0].id, {"url": url, "selected":false}, function(tab){});
        vd.incrementDownloadCount();
    });
};
vd.castVideo = function (url) {


};

vd.extractHostname =  function(url) {
    var hostname;
    //find & remove protocol (http, ftp, etc.) and get hostname

    if (url.indexOf("://") > -1) {
        hostname = url.split('/')[2];
    }
    else {
        hostname = url.split('/')[0];
    }

    //find & remove port number
    hostname = hostname.split(':')[0];
    //find & remove "?"
    hostname = hostname.split('?')[0];

    return hostname;
};

// To address those who want the "root domain," use this function:
vd.extractRootDomain = function(url) {
    var domain = vd.extractHostname(url),
        splitArr = domain.split('.'),
        arrLen = splitArr.length;

    //extracting the root domain here
    //if there is a subdomain
    if (arrLen > 2) {
        domain = splitArr[arrLen - 2] + '.' + splitArr[arrLen - 1];
        //check to see if it's using a Country Code Top Level Domain (ccTLD) (i.e. ".me.uk")
        if (splitArr[arrLen - 2].length === 2 && splitArr[arrLen - 1].length === 2) {
            //this is using a ccTLD
            domain = splitArr[arrLen - 3] + '.' + domain;
        }
    }
    return domain;
};

vd.colorizeExtensionIcon = function(colorize, tabId) {
    // console.trace("Coloriziing");
    colorize ? chrome.browserAction.setIcon({ tabId: tabId, path: "../icons/icon_active.png" }) :  chrome.browserAction.setIcon({ tabId: tabId, path: "../icons/icon_inactive.png" })
};

vd.removeParams=function (url){
    return url.replace(/[#\?].*$/, '');
};


vd.on4KDataReceived = function(result, tab) {
    // console.log(result);
    let fourKData = typeof result === 'string' ? JSON.parse(result) : result;
    fourKData.tabUrl = tab.url;
    vd.getStoredSettings(function (items) {
        let isLoggedInAndUpgraded = (items.logged_in && items.upgraded !== 'false');
        if(fourKData.title && vd.isVideoLinkTypeValid({extension : "."+fourKData.ext}, items.videoTypes) && isLoggedInAndUpgraded) {
            vd.colorizeExtensionIcon(true, tab.id);
        }
    });
    vd.storeFourKData(fourKData);
};

vd.getAllSavedVideoData = function() {
    vd.isLoggedInAndUpgraded(function(bool) {
        // console.log("Is logged in and upgraded", bool);
        if(!bool && vd.version !== "FREE") { return }
        $.get(vd.serverUrl+"video_list/get_all_video_data", function (response) {
            response = vd.convertToJson(response);
            let savedVideos = {};
            if(!response.status) {
                if(response.statusDescription === "Login required") {
                    vd.autoLogin(function(response) {
                        if(response.status) {
                            vd.getAllSavedVideoData();
                        }
                    });
                }
                return
            }
            response.videos.forEach(function (video) {
                savedVideos[video.md5] = video;
            });
            vd.savedVideos = savedVideos;
        });
    });
};

vd.getSavedVideoData = function(md5) {
    $.get(vd.serverUrl+"video_list/get_saved_video?unique_id="+md5, function (response) {
        response = vd.convertToJson(response);
        if(!response.status) {
            if(response.statusDescription === "Login required") {
                vd.autoLogin(function(response) {
                    if(response.status) {
                        vd.vd.getSavedVideoData(md5);
                    }
                });
            }
            return}
        response.videos.forEach(function (video) {
            vd.savedVideos[video.md5] = video;
        });
    });
};

vd.onWebPageLoaded = function(tab) {
    vd.isLoggedInAndUpgraded(function(bool) {
        if(!vd.bg4KVideoCheckForAllUsers && !bool) {
            return
        }
        if(vd.requestedUrlInfo[tab.url]) { return; }
        vd.requestedUrlInfo[tab.url] = 1;
        if(chrome.runtime.lastError){
           // console.log("error: ", chrome.runtime.lastError);
        }
        let urlId = md5(tab.url);
        let fourKData = JSON.parse(localStorage.getItem(urlId));
        vd.is4KDataExpired(fourKData, function (expired) {
            // console.log("is expired", expired);
            // console.log(fourKData);
            if(expired){
                vd.get4KData(tab.url, function (data) {
                    delete vd.requestedUrlInfo[tab.url];
                    vd.on4KDataReceived(data, tab);
                });
            } else {
                vd.getStoredSettings(function (items) {
                    fourKData = fourKData.value;
                    if(fourKData.title && vd.isVideoLinkTypeValid({extension : "."+fourKData.ext}, items.videoTypes)) {
                        vd.colorizeExtensionIcon(true, tab.id);
                    }
                })
            }

        });

    });
};

vd.getVideoTypeFromUrl = function (link) {
    var videoType = null;
    vd.allVideoFormats.some(function (format) {
        if (new RegExp(vd.escapeRegExp('.' + format)).test(link)) {
            videoType = format;
            return true;
        }
    });
    return videoType;
};

vd.getVimeoDataFromServer = function(dataUrl, tab) {
    // console.log(dataUrl);
    // console.log(tab);
    $.get(dataUrl.trim(), function (response) {
        // console.log("response received from vimeo");
        response = typeof response == 'string' ? JSON.parse(response) : response;
        var title = response.video.title;
        var videoLinks = [];
        // console.log(response.request.files.progressive);
        response.request.files.progressive.forEach(function (obj) {
            videoLinks.push({
                url: obj.url,
                fileName: title,
                title: title,
                webpage_url: window.location.href,
                extension: "." + vd.getVideoTypeFromUrl(obj.url),
                quality: obj.quality,
                thumb: response.video.thumbs["640"]
            });
        });
        // console.log(videoLinks);
        vd.addVideoLinks(videoLinks, tab.id, tab.url);
    });
};

vd.getLoginStatus = function() {
   /* $.get(vd.serverUrl+"login_status", function (response) {
        response = typeof response == 'string' ? JSON.parse(response) : response;
        if(!response.status) {return}
        chrome.storage.sync.set({
            logged_in: response.data.logged_in,
            upgraded: response.data.upgraded ? "true" : "false",
        }, function () {
        });
    });*/
    chrome.cookies.get({url: vd.serverUrl, "name":"auth"}, function(data){
        var loginStatus = {
            logged_in: false,
            upgraded: 'false'
        };
        try{
            loginStatus = JSON.parse(decodeURIComponent(data.value));
        }catch(e) {
        }
        // console.log(loginStatus);
        chrome.storage.sync.set({
            logged_in: loginStatus.logged_in,
            upgraded: loginStatus.upgraded ? 'true' : 'false'
        }, function () {
        });
    })
};

vd.syncData = function () {
    // console.log("Syncing data");
    vd.getAllSavedVideoData();
    vd.getLoginStatus();
};

vd.syncData();

setInterval(function () {
    // console.log("Getting saved video data");
    vd.syncData();
}, 30000);

vd.getStoredSettings(function (items) {
    minVideoSize = items.minVideoSize
});

chrome.runtime.onInstalled.addListener(function(details){
  if(details.reason === "install"){
    localStorage.setItem('total_number_of_downloads',0);
  }
});

chrome.webRequest.onHeadersReceived.addListener(function(details){
        // For chrome casting youtube
    // console.log("Google video on header received");
    // console.log(details.url);
        let hasAccessOrigin = false;
        details.responseHeaders.forEach(function(v,i,a){
            let name = v.name.toLocaleLowerCase();
            if( name === "access-control-allow-origin"){
                hasAccessOrigin = true;
            }
        });
        if(!hasAccessOrigin) {
            details.responseHeaders.push({name:"Access-Control-Allow-Origin",value:"*"});
        }
        return {responseHeaders:details.responseHeaders}; //I kill the redirect
    },
    {urls: ["https://*.googlevideo.com/*"]},["responseHeaders","blocking"]);

chrome.tabs.onUpdated.addListener(function (tabId, changeInfo, tab) {
    if(!changeInfo.url) {return}
    // console.log(changeInfo);
    // console.log("Tab updated");
    vd.colorizeExtensionIcon(false, tabId);
    vd.resetVideoLinks(tabId);
    chrome.tabs.sendMessage(tabId, {message: "initialize-page", url: changeInfo.url});
});

chrome.tabs.onRemoved.addListener(function (tabId) {
  if(vd.tabsData[tabId]) {
    delete vd.tabsData[tabId];
  }
});

chrome.webRequest.onHeadersReceived.addListener(vd.inspectNetworkResponseHeaders, {urls: ["<all_urls>"]}, ["blocking","responseHeaders"]);

chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
    // console.log(request);
    // console.log(sender);
    switch (request.message) {
        case "reset-video-links":
            vd.resetVideoLinks(sender.tab.id, sender.tab.url);
            sendResponse();
            break;
        case "add-video-links":
            // console.log('adding video links');
            vd.addVideoLinks(request.videoLinks, sender.tab.id, sender.tab.url);
            sendResponse("Message received.");
            break;
        case "on-web-page-loaded" :
            vd.onWebPageLoaded(sender.tab);
            sendResponse("Received the message.");
            break;
        case "get-video-links" :
            sendResponse(vd.getVideoLinksForTab(request.tabId));
            break;
        case "download-video-link" :
            vd.downloadVideoLink(request.url, request.fileName);
            break;
        case "show-youtube-warning" :
            vd.showYoutubeWarning();
            break;
        case "cast-video" :
            vd.castVideo(request.url);
            break;
        case "is-video-saved" :
            sendResponse(vd.savedVideos[request.tabUrlMd5]);
            break;
        case "add-saved-video" :
            vd.savedVideos[request.video.md5] = request.video;
            sendResponse();
            break;
        case "remove-saved-video" :
            delete vd.savedVideos[request.tabUrlMd5];
            sendResponse();
            break;
        case "create-vimeo-video-links" :
            vd.getVimeoDataFromServer(request.dataUrl, sender.tab);
            sendResponse("Message received.");
            break;
        case "activate-ext-icon" :
            if(sender.tab) {
                vd.colorizeExtensionIcon(request.activate, sender.tab.id);
            }
            break;
        case "update-min-vid-size" :
            minVideoSize = request.minVideoSize;
            break;
    }
});
