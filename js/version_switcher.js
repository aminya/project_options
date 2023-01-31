function replaceContentInContainer(matchClass, content) {
    var elems = document.getElementsByTagName('*'), i;
    for (i in elems) {
        if ((' ' + elems[i].className + ' ').indexOf(' ' + matchClass + ' ')
            > -1) {
            elems[i].innerHTML = content;
        }
    }
}

function ar_updateVersionList(current_version) {
    console.log(ar_versions, current_version);

    var versions_html = ["<dl><dt>Versions</dt>"];
    var downloads_html = ["<dl><dt>Downloads</dt>"];
    var show_downloads = false
    for (const version of ar_versions) {
        var version_link = '<dd><a href="../' + version.folder + '"/index.html>' + version.version + '</a></dd>'
        var download_link = ''
        if (version.has_pdf) {
            download_link = '<dd><a href="../' + version.folder + '/' + version.pdf_name + '">' + version.version + '</a></dd>'
            show_downloads = true
        }
        if (version.version === current_version) {
            versions_html.push("<strong>")
            versions_html.push(version_link)
            versions_html.push("</strong>")
            downloads_html.push("<strong>")
            downloads_html.push(download_link)
            downloads_html.push("</strong>")
        } else {
            versions_html.push(version_link)
            downloads_html.push(download_link)
        }
    }
    versions_html.push("</dl>")
    downloads_html.push("</dl>")
    replaceContentInContainer("rst-other-versions", versions_html.join("") + (show_downloads ? downloads_html.join("") : ""))
}
