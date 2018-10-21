import qbs

Project {
    minimumQbsVersion: "1.6.0"

    Product
    {
        property string optimization: "fast"

        type: ["application", "flash"]

        Depends
        {
            name: "cpp"
        }

        cpp.defines: ["STM32L476xx"]
        cpp.positionIndependentCode: false
        cpp.enableExceptions: false
        cpp.executableSuffix: ".elf"
        cpp.cxxFlags: ["-std=c++14"]
        cpp.cFlags: ["-std=gnu99"]

        Properties
        {
            condition: qbs.buildVariant === "debug"
            cpp.defines: outer.concat(["DEBUG=1"])
            cpp.debugInformation: true
            cpp.optimization: "none"
        }

        Properties
        {
            condition: qbs.buildVariant === "release"
            cpp.debugInformation: false
            cpp.optimization: optimization
        }

        files:
        [
            "src/rtc.cpp",
            "src/rtc.h",
            "system/cmsis/device/include/*.h",
            "system/cmsis/device/source/*.c",
            "system/cmsis/include/*.h",
            "system/startup/*.s",
            "src/main.cpp",
        ]

        cpp.driverFlags:
        [
            "-mcpu=cortex-m4",
            "-mthumb",
            "-mfloat-abi=hard",
            "-mfpu=fpv4-sp-d16",
            "-g3",
            "-Wall",
            "-fmessage-length=0",
            "-ffunction-sections"
        ]

        cpp.commonCompilerFlags:
        [
            "-mcpu=cortex-m4",
            "-mthumb",
            "-mfloat-abi=hard",
            "-mfpu=fpv4-sp-d16",
            "-g3",
            "-Wall",
            "-fmessage-length=0",
            "-ffunction-sections"
        ]

        cpp.linkerFlags:
        [
            "-T" + path + "/system/linker/stm32l4xx_flash.ld",
            "-Map=output.map",
            "--gc-sections",
            "-lm"
        ]

        cpp.includePaths:
        [
                  "system/cmsis/include",
                  "system/cmsis/device/include",
                  "system/cmsis/device/source",
                  "system/startup"
        ]

        Rule
        {
            inputs: ["application"]

            Artifact
            {
                filePath: project.buildDirectory + ".hex"
                fileTags: "flash"
            }

            prepare:
            {
                var GCCPath = "/opt/ARM/gcc-arm-none-eabi/bin"
                var OpenOCDPath = "/opt/ARM/openocd-0.10.0"
                var OpenOCDInterface = "stlink.cfg"
                var OpenOCDTarget = "stm32l4x.cfg"

                var argsSize = [input.filePath]
                var argsObjcopy = ["-O", "ihex", input.filePath, output.filePath]

                var argsFlashing =
                [
                            "-f", OpenOCDPath + "/scripts/interface/" + OpenOCDInterface,
                            "-f", OpenOCDPath + "/scripts/target/" + OpenOCDTarget,
                            "-c", "init",
                            "-c", "halt",
                            "-c", "flash write_image erase " + input.filePath,
                            "-c", "reset",
                            "-c", "shutdown"
                ]

                var cmdSize = new Command(GCCPath + "/arm-none-eabi-size", argsSize)
                var cmdObjcopy = new Command(GCCPath + "/arm-none-eabi-objcopy", argsObjcopy)
                var cmdFlash = new Command(OpenOCDPath + "/bin/openocd", argsFlashing);

                cmdSize.description = "Size of sections:"
                cmdSize.highlight = "linker"

                cmdObjcopy.description = "convert to bin..."
                cmdObjcopy.highlight = "linker"

                cmdFlash.description = "download firmware to uC..."
                cmdFlash.highlight = "linker"

                return [cmdSize, cmdObjcopy, cmdFlash]
            }
        }
    }
}
