#!/usr/bin/env ruby

# Ref: https://github.com/aseprite/aseprite/blob/main/INSTALL.md

require_relative "runner"

builder = Runner.new do

  task "clean" do
    sh "rm -rf aseprite"
    sh "rm -rf mount"
    sh "rm -rf *.zip"
    sh "rm -rf *.app"
    sh "rm -rf *.dmg"
  end

  task "check xcode" do
    puts "On macOS you will need macOS 11.3 SDK and Xcode 13.1 (older versions might work).".yellow
    puts "Your Xcode version:".yellow
    sh "xcodebuild -version"
    puts "Your SDK Version:".yellow
    sh "xcodebuild -showsdks | grep macOS"
  end

  task "download aseprite" do
    sh "git clone --recursive https://github.com/aseprite/aseprite.git"
    sh "cd aseprite && git pull && git submodule update --init --recursive"
  end

  task "install build dependencies" do
    puts "Need The latest version of CMake (3.16 or greater)".yellow
    sh "brew install cmake ninja"
  end

  task "download Skia library" do
    prefix = @macos_arch == "arm64" ? "arm64": "x64"
    sh "curl -O -L 'https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-macOS-Release-#{prefix}.zip'"
    sh "unzip Skia-macOS-Release-#{prefix}.zip -d aseprite/skia-m124"
  end

  task "build aseprite" do
    prefix = @macos_arch == "arm64" ? "arm64": "x64"

    arm_tag = @macos_arch == "arm64" ?  '-DPNG_ARM_NEON:STRING=on' : ''

    command_code = <<~SHELL
cd aseprite &&  mkdir build &&  cd build && \
export SKIA_ABS_PATH="$(pwd)/../skia-m124" && \
cmake \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_OSX_ARCHITECTURES=#{@macos_arch == "arm64" ? "arm64" : "x86_64"} \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=#{@macos_arch == "arm64" ? "11.0" : "10.9"} \
  -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
  -DLAF_BACKEND=skia \
  -DSKIA_DIR="$SKIA_ABS_PATH" \
  -DSKIA_LIBRARY_DIR="$SKIA_ABS_PATH/out/Release-#{prefix}" \
  -DSKIA_LIBRARY="$SKIA_ABS_PATH/out/Release-#{prefix}/libskia.a" \
  #{arm_tag} \
  -G Ninja .. && \
ninja aseprite

SHELL
    sh command_code
  end

  # task "build local Aseprite.app" do
  #  sh "mkdir -p Aseprite.app/Contents"
  #  sh "cp -r ./aseprite/build/bin ./Aseprite.app/Contents/"
  #  sh "mv ./Aseprite.app/Contents/bin ./Aseprite.app/Contents/MacOS"
  # end

  task "build Aseprite.app from trial app" do
    sh 'curl -O -J "https://www.aseprite.org/downloads/trial/Aseprite-v1.3.14.3-trial-macOS.dmg"'
    sh "mkdir mount"
    sh "yes qy | hdiutil attach -quiet -nobrowse -noverify -noautoopen -mountpoint mount ./Aseprite-v1.3.14.3-trial-macOS.dmg"
    sh "cp -r mount/Aseprite.app ."
    sh "hdiutil detach mount"
    sh "rm -rf ./Aseprite.app/Contents/MacOS/aseprite"
    sh "cp -r ./aseprite/build/bin/aseprite ./Aseprite.app/Contents/MacOS/aseprite"
    sh "rm -rf ./Aseprite.app/Contents/Resources/data"
    sh "cp -r ./aseprite/build/bin/data Aseprite.app/Contents/Resources/data"
  end


  task "install Aseprite.app" do
    sh "sudo cp  -r ./Aseprite.app /Applications/"
  end
end

builder.run
