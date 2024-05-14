systemtrayId = applet.readConfig("SystrayContainmentId");
if (systemtrayId) {
    const systrayContainer = desktopById(systemtrayId);
    systrayContainer.currentConfigGroup = ["General"];
    systrayContainer.writeConfig("scaleIconsToFit", true);
}
