var currentVolume = 0.5;
var cookieName;
var videoTypes = [];
var tabUrlMd5 = '';
var savedVideos = {};
var storedSettings = {};
vd.sendMessage = function (message, callback) {
    chrome.runtime.sendMessage(message, callback);
};

vd.videoLinks = [];

vd.getChromeCastButton = function(videoData) {
    // console.log(videoData);
    return '<a href="' + (videoData.streaming_url ? videoData.streaming_url : videoData.url) + '" data-thumb="' + (videoData.thumbnail || videoData.thumb) + '" data-title="' + (videoData.fileName || videoData.title)  + '" data-href="' + (videoData.url||videoData.streaming_url) + '" class="cast-button" data-file-name="'+videoData.fileName + videoData.extension+'" data-domain="'+videoData.d+'"></a>';
};

vd.createDownloadSection = function (videoData, chromeCast) {
    var mathFloor = Math.floor(videoData.size * 100 / 1024 / 1024) / 100;
    var chromeCostString = "";
    // console.log(">>>>>>>");
    // console.log(chromeCast);
    if (chromeCast !== false) {
        chromeCostString = vd.getChromeCastButton(videoData);
    }
    return '<li class="video" data-thumb="" data-link="'+videoData.webpage_url+'" data-title="'+videoData.title+'">\
    <div class="video_list_L"> <a class="play-button" href="' + videoData.url + '" target="_blank"></a> </div>\
    <div class="title" title="' + videoData.fileName + '">' + videoData.fileName + '</div>\
    <div class="video_list_R">' + chromeCostString + '<a class="download-button btn-instant-download btn btn-sm btn33 " href="' + videoData.url + '" data-file-name="' + videoData.fileName + videoData.extension + '">Download - ' + mathFloor + ' MB</a> </div>\
    <div class=" clearfix"></div>\
    <div class="sep"></div>\
</li>';

};

vd.removeParams = function (url) {
    return url.replace(/[#\?].*$/, '');
};

vd.addYoutubeInfo = function(data) {
    // console.log("Adding youtube info for chrome");
    let fourKData = typeof data === 'string' ? JSON.parse(data) : data;
    let videoList = $("#video-list");
    let chromeCastHtml = "";
    let fourKString = '';
    let fourKDownloadUrl;
    let dButtonStr;
    fourKDownloadUrl = "https://bllonet.com/disabled/";
    dButtonStr = '<a class="btn btn-default btn33 btn-sm btn34" href="' + fourKDownloadUrl + '" target="_blank">More Info</a>';
    fourKString = '<li class="video" data-thumb="'+fourKData.thumbnail+'" data-link="'+fourKData.webpage_url+'" data-title="'+fourKData.title+'">' +
        '<a class="play-button" href="' + fourKData.webpage_url + '" target="_blank"></a>' +
        '<div class="title" title="' + fourKData.title + ' ' + fourKData.formatTtile + ' (' + fourKData.ext + ')">' + fourKData.title + ' ' + fourKData.formatTtile + ' (' + fourKData.ext + ')</div>' +
        '<div class="video_list_R">' + chromeCastHtml + dButtonStr +'</div>' +
        '<div class=" clearfix"></div>' +
        '<div class="sep"></div>' +
        '</li>';
    videoList.prepend(fourKString);
    if(videoList.find("li").length > 0) {
        vd.showVideoList();
    } else {
        vd.emptyVideoList();
        vd.sendMessage({message: "activate-ext-icon", activate: false});
        $("#no-video-found").css('display', 'block');
    }
   // console.log("Hiding after youtube info");
    $("#loading").hide();
    vd.showSaveForLaterButton();
};

vd.add4KLink = function (data, settings, callback) {
    // console.log(data);
    let fourKData = typeof data === 'string' ? JSON.parse(data) : data;
    let videoList = $("#video-list");
    let size = " Premiem";
    let duration = 0;
    let chromeCastHtml = "";
    let fourKString = '';
    let fourKDownloadUrl = '';
    let dButtonStr = '';
    if(fourKData.webpage_url.includes("https://www.youtube.com") && vd.extension === "chrome") {
        settings.isYoutube = true;
    }
    if(settings.isYoutube) {settings.chromeCast = false}
    if(fourKData && !fourKData.streaming_url) {
        fourKData.streaming_url = fourKData.baseurl;
    }

    vd.getLoginToken(function(loginToken) {
        if (vd.is4KDataValid(fourKData) && vd.isVideoSizeValid(fourKData, settings.minVideoSize) && vd.isVideoLinkTypeValid({extension : "."+fourKData.ext}, videoTypes)) {
            fourKDownloadUrl = settings.isYoutube? "https://bllonet.com/disabled/" : vd.serverUrl + "video/convert?videourl=" + fourKData.webpage_url + "&format=" + fourKData.format + "&filename=" + fourKData._filename+"&lt="+loginToken;
            dButtonStr = settings.isYoutube ? '<a class="btn btn-sm btn33 btn34" href="' + fourKDownloadUrl + '" target="_blank">More Info</a>' : '<a class="download-button btn-four-k-download four-k btn btn-sm btn33" href="' + fourKDownloadUrl + '" data-web-page="'+fourKData.webpage_url+'">Download -' + size + '</a>';
            // $(".loader22").remove();

            if (fourKData.filesize != null) {
                size = (fourKData.filesize / 1024 / 1024).toFixed(2);
                size = size + " MB";
            }

            if (fourKData.duration != null) {
                duration = Math.round(fourKData.duration / 60);
                duration = duration + " Mins";
            }

            if (settings.chromeCast !== false) {
                chromeCastHtml =  vd.getChromeCastButton(fourKData);
            }

            fourKString = '<li class="video" data-thumb="'+fourKData.thumbnail+'" data-link="'+fourKData.webpage_url+'" data-title="'+fourKData.title+'"><a class="play-button" href="' + fourKData.webpage_url + '" target="_blank"></a><div class="title" title="' + fourKData.title + ' ' + fourKData.formatTtile + ' (' + fourKData.ext + ')">' + fourKData.title + ' ' + fourKData.formatTtile + ' (' + fourKData.ext + ')</div><div class="video_list_R">' + chromeCastHtml + dButtonStr +'</div><div class=" clearfix"></div><div class="sep"></div></li>';
            videoList.prepend(fourKString);
        }
        callback();
    });
};

vd.on4KDataReceived = function (result, settings, callback) {
    let fourKData = typeof result === 'string' ? JSON.parse(result) : result;
    vd.add4KLink(fourKData, settings, callback);
};

vd.getValidYtLink = function (links) {
    let validLink = {};
    links.some(function (link) {
        if (link.thumbnail) {
            validLink = link;
            return true
        }
    });
    // console.log(validLink);
    return validLink;
};

vd.createDownloadSection4KVideo = function (videoPageUrl, settings, callback) {
    // console.log("Creating 4K link");
    // $("#video-list").append('<li class="loader22"> <img  style="height:60px"  src="https://cdn.dribbble.com/users/225707/screenshots/2958729/attachments/648705/straight-loader.gif"  alt=""/></li>');
    settings.isYoutube = settings.isYoutube && vd.extension === "chrome";
    if(settings.isYoutube) {
        // console.log("Youtube >>>");
        chrome.tabs.query({active: true}, function (tabs) {
            let tabId = tabs[0].id;
            chrome.tabs.sendMessage(tabId, {message: 'get-youtube-data', userType:"Free"}, function () {
                // Data will be received asynchronously to the chrome.runtime.onMessage listener
            });
        });
        return;
    }
    // console.log("Not chrome");
    let urlId = md5(videoPageUrl);
    let videoData = JSON.parse(localStorage.getItem(urlId));
   // console.log(urlId);
    vd.is4KDataExpired(videoData, function (expired) {
       // console.log("Expired", expired);
        if(videoData && !expired) {
            let fourKData = videoData.value;
            vd.add4KLink(fourKData, settings, callback);
        } else {
            localStorage.removeItem(urlId);
            vd.get4KData(videoPageUrl, function (result) {
               // console.log(videoPageUrl);
                result = vd.convertToJson(result);
                if(!result) {
                    localStorage.removeItem(urlId);
                    callback();
                    return;
                }
                result.tabUrl = videoPageUrl;
                vd.storeFourKData(result);
                vd.on4KDataReceived(result, settings, callback);
            })
        }
    });

};


vd.onVideoListChanged = function () {

};

vd.emptyVideoList = function () {
    let videoList = $("#video-list");
    videoList.html("");
    videoList.css('display', 'none');
};

vd.showVideoList = function () {
    let videoList = $("#video-list");
    vd.sendMessage({message: "activate-ext-icon", activate: true});
    $("#no-video-found").css('display', 'none');
    videoList.css('display', 'block');
};

vd.showSaveForLaterButton = function() {
    let videoList = $("#video-list");
    if(videoList.find("li").length > 0) {
        $("#bookmark-video").show();
    }
};

vd.changeSaveVideoBtnStatus = function(enable) {
    let faBookmark = $(".fa-bookmark");
    // let saveButton = $(".btn-save-video");
    if(!enable) {
        faBookmark.css('color', '#ff0b46');
        // saveButton.prop('disabled', true);
    } else {
        faBookmark.css('color', '#555');
        // saveButton.prop('disabled', false);
    }
};

vd.showSaveVideoLoading = function() {
    $(".fa-bookmark").hide();
    $("#loading2").show();
};

vd.hideSaveVideoLoading = function() {
    // console.log("Hiding loading");
    $(".fa-bookmark").show();
    $("#loading2").hide();
};

vd.saveVideoForLater = function(video) {
    $.ajax({
        type: "POST",
        url: vd.serverUrl+"video_list/add_video",
        data: video,
        success: function (response) {
            response = vd.convertToJson(response);
            if(!response.status && response.statusDescription === "Login required") {
                vd.autoLogin(function (response) {
                    if(response.status) {
                        vd.saveVideoForLater(video);
                    } else {
                        window.open(vd.serverUrl+"login", "_blank");
                    }
                });
                return
            } else if (!response.status && response.statusDescription === "Subscription required") {
                window.open(vd.serverUrl+"pricing", "_blank");
                return;
            }
            let videoSavedSuccessfully = response.status === 1;
            vd.changeSaveVideoBtnStatus(!videoSavedSuccessfully);
            vd.hideSaveVideoLoading();
            $('.btn-save-video').attr('data-video-id', response.video.id);
            savedVideos[response.video.id] = response.video;
            vd.sendMessage({message: "add-saved-video", video: response.video});
        },
        error: function (jqXHR, textStatus, errorThrown) {
            // console.log(jqXHR, textStatus, errorThrown);
            vd.saveVideoForLater(video);
        }
    })
};

vd.deleteSavedVideo = function(id) {
    vd.showSaveVideoLoading();
    vd.getLoginToken(function (loginToken) {
        let deleteSavedVideoFinal = function() {
            delete savedVideos[tabUrlMd5];
            vd.sendMessage({message: "remove-saved-video", tabUrlMd5 : tabUrlMd5});
            vd.changeSaveVideoBtnStatus(true);
            $('.btn-save-video').attr('data-video-id','');
            vd.hideSaveVideoLoading();
        };
        $.post(vd.serverUrl+"video_list/delete_video", {id: parseInt(id), lt: loginToken}, function (response) {
            response = vd.convertToJson(response);
            if(!response.status) {
                if(response.statusDescription === "Login required") {
                    // console.log("About to do auto login");
                    vd.autoLogin(function (response) {
                        // console.log("Auto login response");
                        // console.log(response);
                        if(response.status) {
                            deleteSavedVideoFinal();
                        } else {
                            window.open(vd.serverUrl+"login", "_blank");
                        }
                    });
                } else if(response.statusDescription === "Subscription required") {
                    window.open(vd.serverUrl+"pricing", "_blank");
                }
                return
            }
            deleteSavedVideoFinal();
        });
    });

};

vd.initializeLoggedInUI = function(items) {
    var myAccountBtn = $(".myaccount");
    // console.log(myAccountBtn);
    myAccountBtn.show();
    (vd.version !== "FREE" && items.upgraded === 'false') ? vd.initializeNotUpgradedUI(items) : vd.initializeUpgradedUI(items);
};

vd.initializeUpgradedUI = function(items) {
    $.each(items.videoTypes,function(key, val){
        $('.video_type[value="' + val + '"]').attr('checked', 'checked');
    });
    var upgradeBtn = $(".upgrade");
    upgradeBtn.hide();

};

vd.initializeNotUpgradedUI = function(items) {
    var upgradeBtn = $(".upgrade");
    upgradeBtn.show();
};

vd.getSavedVideoData = function() {
    // console.log("Checking if video is saved", tabUrlMd5);
    vd.sendMessage({message: "is-video-saved", tabUrlMd5: tabUrlMd5}, function(video) {
        // console.log(video);
        if(video) {
            vd.changeSaveVideoBtnStatus(false);
            // console.log(video);
            $('.btn-save-video').attr('data-video-id', video.id);
        }
        vd.hideSaveVideoLoading();
    })
};

vd.afterDataLoaded = function() {
    // console.log("After downloading finished");
    console.trace("Hid >>>");
    let videoList = $("#video-list");
    vd.getStoredSettings(function (items) {
        let videoCount = videoList.find("li").length ;
        $("#loading").hide();
        if (videoCount) {
            vd.showSaveForLaterButton();
        }
        if(!items.logged_in) {
            $("#loading2").hide();
        }
        if(videoCount) {
            vd.showVideoList();
        } else {
            $("#no-video-found").css('display', 'block');
        }
        if (!items.logged_in || (vd.version !== "FREE" && items.upgraded === 'false')) {
            $(".my-list").hide();
        }
    });

};

$(document).ready(function () {
    let body = $('body');
    let btnUpgrade = $(".upgrade");
    $(".my-list-a").attr('href', vd.serverUrl+"video_list");
    vd.showSaveVideoLoading();
    vd.version === "FREE" ?  btnUpgrade.find(".btn-label").text("Login") : btnUpgrade.find(".btn-label").text("Upgrade");

    vd.getStoredSettings(function (items) {
        // console.log("LLL");
        // console.log(items);
        storedSettings = items;
        if (items.logged_in) {
            vd.initializeLoggedInUI(items);
        }
    });

    body.on('click', ".myaccount", function () {
        let newURL = vd.serverUrl + "account";
        chrome.tabs.create({url: newURL});
    });

    let videoList = $("#video-list");
    $('#go-to-options').on('click', function () {
        if (chrome.runtime.openOptionsPage) {
            chrome.runtime.openOptionsPage();
        } else {
            window.open(chrome.runtime.getURL('html/options.html'));
        }
    });
    $('.upgrade').on('click', function () {
        var newURL = vd.version === "FREE" ?  vd.serverUrl + "account" : vd.serverUrl + "pricing";
        chrome.tabs.create({url: newURL});
    });

    chrome.tabs.query({active: true, currentWindow: true}, function (tabs) {
        // console.log(tabs);
        tabUrlMd5 = md5(tabs[0].url);
        vd.sendMessage({message: 'get-video-links', tabId: tabs[0].id}, function (tabsData) {
            // console.log(tabsData);
            vd.videoLinks = tabsData.videoLinks;
            if(!tabsData.url) {
               // console.log("Hiding after video links received>>>>");
                vd.emptyVideoList();
                $("#no-video-found").css('display', 'block');
                $("#loading").hide();
                return
            }

            vd.emptyVideoList();
            vd.getStoredSettings(function (items) {
                let isYoutube = tabsData.url.indexOf('youtube.com') !== -1;
                let isLoggedInAndUpgraded = (items.logged_in && (items.upgraded !== 'false' || vd.version === "FREE"));
                let showChromecast = items.chromeCast;
                // let showChromecast = true;
                // console.log("Got stored settings", items);
                if ((!items.logged_in || (items.upgraded === 'false' && vd.version !== "FREE"))  &&  isYoutube) {
                    chrome.tabs.query({active: true}, function (tabs) {
                        let tabId = tabs[0].id;
                        chrome.tabs.sendMessage(tabId, {message: 'get-youtube-data', userType: 'paid'}, function () {
                            // Data will be received asynchronously to the chrome.runtime.onMessage listener
                        });
                    });
                    vd.getSavedVideoData();
                    // vd.sendMessage({message: 'show-youtube-warning'});
                    if(vd.extension === "chrome") {
                        vd.afterDataLoaded();
                        return 0;
                    }
                }
                // console.log("Continuing since it's not chrome");
                videoTypes = items.videoTypes;
                vd.videoLinks.forEach(function (videoLink) {
                    // console.log(videoLink);
                    if (!vd.isVideoLinkTypeValid(videoLink, items.videoTypes) || !vd.isVideoSizeValid(videoLink, items.minVideoSize) || (isYoutube && vd.extension === "chrome")) {
                        return
                    }
                    videoList.append(vd.createDownloadSection(videoLink, showChromecast));
                });
                // console.log(videoList);
                vd.getSavedVideoData();
                if(videoList.find("li").length > 0) {
                    vd.showVideoList();
                }
                vd.createDownloadSection4KVideo(tabsData.url,{
                    chromeCast : showChromecast,
                    isYoutube: isYoutube,
                    minVideoSize: items.minVideoSize
                }, vd.afterDataLoaded);
                if (!items.logged_in || (items.upgraded === 'false' && vd.version !== "FREE")) {
                    $(".my-list").hide();
                }
            });
        });
    });

    body.on('click', '.btn-save-video', function (e) {
        e.preventDefault();
        let btn = $(this);
        if(btn.attr('data-video-id')) {
            vd.deleteSavedVideo(btn.attr('data-video-id'));
            return;
        }
        vd.showSaveVideoLoading();
        let videoList = $("#video-list");
        if (!videoList.find("li").length) {return}
        let videoElem = videoList.find("li").eq(0);
        let link = videoElem.attr('data-link').trim();
        let video = {
            title : videoElem.attr('data-title'),
            link : link,
            thumbnail : videoElem.attr('data-thumb'),
            md5 : md5(link)
        };
        vd.getLoginToken(function (loginToken) {
            video.lt = loginToken;
            vd.saveVideoForLater(video);
        });
    });

    body.on('click', '.btn-instant-download', function (e) {
        e.preventDefault();
        vd.sendMessage({
            message: 'download-video-link',
            url: $(this).attr('href'),
            fileName: $(this).attr('data-file-name')
        });
    });

    body.on('click', '.btn-four-k-download', function (e) {
        e.preventDefault();
        let videoUrl = $(this).data('web-page');
        $.post(vd.serverUrl+"video", {videoUrl: videoUrl}, function (response) {
            response = vd.convertToJson(response);
            if(!response.status) {
                return
            }
            var downloadPageUrl = vd.serverUrl + "video/download/?id=" + response.data;
            // console.log(downloadPageUrl);
            chrome.tabs.create({url: encodeURI(downloadPageUrl)});

        });
    });

    body.on('click', '.cast-button', function (e) {
        e.preventDefault();
        let link = $(this);
        var url = link.attr('href');
        var title = link.data('title');
        var thumb = link.data('thumb');
        var siteDomain = link.data('domain');
        // url = encodeURI(url).re
        thumb = (thumb && thumb !== "undefined") ? thumb : null;
        title = (title && title !== "undefined") ? title : null;
        siteDomain = (siteDomain && siteDomain !== "undefined") ? siteDomain : null;
        $.post(vd.serverUrl+"chrome_cast", {videoCastUrl: url, videoTitle: title, videoThumb: thumb, siteDomain: siteDomain }, function (response) {
            response = vd.convertToJson(response);
            if(!response.status) {
                return
            }
            var castPlayerUrl = vd.serverUrl + "chrome_cast/play/?id=" + response.data;
            // console.log(castPlayerUrl);
            chrome.tabs.create({url: encodeURI(castPlayerUrl)});

        });
    });
});

chrome.runtime.onMessage.addListener(function (request, sender, sendResponse) {
    switch (request.message) {
        case "add-video-links":
           if(!request.videoLinks[0]) {return}
            vd.add4KLink(request.videoLinks[0], {
                chromeCast : storedSettings.chromeCast,
                isYoutube: false,
                minVideoSize: storedSettings.minVideoSize
            }, vd.afterDataLoaded);
            break;
        case "add-youtube-info-for-chrome":
            vd.addYoutubeInfo(request.videoLinks[0]);
            break;
    }
});
