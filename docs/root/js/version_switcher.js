function replaceContentInContainer(matchClass, content) {
	const elements = document.getElementsByTagName("*");
	for (const element in elements) {
		if (` ${elements[element].className} `.includes(` ${matchClass} `)) {
			elements[element].innerHTML = content;
		}
	}
}

function ar_updateVersionList(current_version) {
	const versions_html = ["<dl><dt>Versions</dt>"];
	const downloads_html = ["<dl><dt>Downloads</dt>"];
	let show_downloads = false;
	for (const version of ar_versions) {
		const version_link = `<dd><a href="../${version.folder}"/index.html>${version.version}</a></dd>`;
		let download_link = "";
		if (version.has_pdf) {
			download_link = `<dd><a href="../${version.folder}/${version.pdf_name}">${version.version}</a></dd>`;
			show_downloads = true;
		}
		if (version.version === current_version) {
			versions_html.push("<strong>");
			versions_html.push(version_link);
			versions_html.push("</strong>");
			downloads_html.push("<strong>");
			downloads_html.push(download_link);
			downloads_html.push("</strong>");
		} else {
			versions_html.push(version_link);
			downloads_html.push(download_link);
		}
	}
	versions_html.push("</dl>");
	downloads_html.push("</dl>");
	replaceContentInContainer(
		"rst-other-versions",
		versions_html.join("") + (show_downloads ? downloads_html.join("") : ""),
	);
}
