


## **THIS REQUIRES MACOS(VM’s/hackintosh works aswell)**

**Vulkan(1.3.275.0):** 

**[ON INSTALL CHECK VULKAN MEMORY ALLOCATOR HEADER]**

https://sdk.lunarg.com/sdk/download/1.3.275.0/mac/vulkansdk-macos-1.3.275.0.dmg

**['$' means run in a command line, do not include $ in the command.]**

**Homebrew:**

**Open terminal copy/paste**
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

$ Brew install wget

**Boost:** 

**Open terminal copy/paste**

$ wget -O boost1.84.zip https://archives.boost.io/release/1.84.0/source/boost_1_84_0.zip

$ unzip boost1.84.zip

$ cd boost_1_84_0

$ sh bootstrap.sh --prefix=/usr/local

$ sudo ./b2 --prefix=/usr/local install 

[it will as for your mac password after this command, it will be hidden so type it properly the first time.]



**[Main Pomelo Instructions]:**

**Open terminal copy/paste**

$ git clone https://gitlab.com/pomelo-emu/Pomelo.git

To build the `Pomelo.xcodeproj` project file and work with it, you'll need to follow these steps:

1. **Install Xcode 15:**
   First, ensure you have Xcode 15 installed on your macOS device. You can download and install Xcode 15 from the Mac App Store using the following link: [Xcode 15](https://apps.apple.com/us/app/xcode/id497799835?mt=12).

2. **Open Pomelo and the Project File:**
   Once Xcode 15 is installed, launch the application. Then, open the Pomelo project by following these steps:
   - Open Finder and locate the Pomelo folder.
   - Navigate into the Pomelo folder and find the `Pomelo.xcodeproj` file.
   - Double-click on `Pomelo.xcodeproj` to open it in Xcode 15.
   - Plug in your Device

3. **Reset Cache and Update Packages:**
   After opening the project in Xcode 15, it's a good practice to reset the cache and update packages to ensure everything is up-to-date and functioning properly. Here's how to do it:
   - Go to the "Product" menu in the Xcode menu bar.
   - Choose "Clean Build Folder" to clear the build cache.
   - After cleaning the build folder, navigate to the "File" menu.
   - Choose "Swift Packages" and then select "Update to Latest Package Versions" to update all Swift packages used in the project.

4. **Build the Project:**
   Once you've reset the cache and updated packages, you're ready to build the project:
   - Click the Pomelo text with the little blue appstore icon that should be on the right bar
   - Then click Signing and Capabilities
   - If you havent logged in to Xcode yet click "None" on the team dropdown and click Add Account then login with your Apple ID.
   - You will need to change the Bundle Identifier to "com.XXXX.XXXX". (the X's mean that you can put whatever you want)
   - You will need to go to the Pomelo text at the top in the Xcode toolbar it should have an arrow next to it then Select your device. (you may need to Install the iOS SDK / Simulator)
   - Click on the "Build" button (a play button icon) on the Xcode toolbar.
   - Xcode will compile the project, and if there are no errors, it will generate the executable or the desired output.

5. **Run the Project:**
   After successfully building the project, you can run it by following these steps:
   - Select the target device or simulator from the scheme dropdown menu located beside the build and stop buttons.
   - Click on the "Run" button (a play button icon) in the Xcode toolbar.
   - Xcode will deploy the project to the selected device, and you should see the application running.
   - After you close the App on your Device you will need to Enable JIT by pressing the Debug menu in the Xcode menu bar then pressing      Attach to Process PID or Name.

By following these steps, you'll be able to install Xcode 15, open the `Pomelo.xcodeproj` project file, reset the cache, update packages, build the project, and run it on your iOS Device.

