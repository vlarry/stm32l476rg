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
                filePath: project.buildDirectory + product.name + ".hex"
                fileTags: "flash"
            }

            prepare:
            {
                var GCCPath = "/opt/ARM/gcc-arm-none-eabi/bin"
                var OpenOCDPath = "/opt/ARM/openocd-0.10.0"
                var OpenOCDInterface = "stlink.cfg"
                var OpenOCDTarget = "stm32l4x.cfg"
//                var OpenOCDTarget = "stm32f0x.cfg"

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
//    --------------------------------------------------------------------
//    | ARM Core | Command Line Options                       | multilib |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M0+| -mthumb -mcpu=cortex-m0plus                | armv6-m  |
//    |Cortex-M0 | -mthumb -mcpu=cortex-m0                    |          |
//    |Cortex-M1 | -mthumb -mcpu=cortex-m1                    |          |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv6-m                     |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M3 | -mthumb -mcpu=cortex-m3                    | armv7-m  |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7-m                     |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M4 | -mthumb -mcpu=cortex-m4                    | armv7e-m |
//    |(No FP)   |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m                    |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M4 | -mthumb -mcpu=cortex-m4 -mfloat-abi=softfp | armv7e-m |
//    |(Soft FP) | -mfpu=fpv4-sp-d16                          | /softfp  |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m -mfloat-abi=softfp |          |
//    |          | -mfpu=fpv4-sp-d16                          |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M4 | -mthumb -mcpu=cortex-m4 -mfloat-abi=hard   | armv7e-m |
//    |(Hard FP) | -mfpu=fpv4-sp-d16                          | /fpu     |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m -mfloat-abi=hard   |          |
//    |          | -mfpu=fpv4-sp-d16                          |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M7 | -mthumb -mcpu=cortex-m7                    | armv7e-m |
//    |(No FP)   |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m                    |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M7 | -mthumb -mcpu=cortex-m7 -mfloat-abi=softfp | armv7e-m |
//    |(Soft FP) | -mfpu=fpv5-sp-d16                          | /softfp  |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m -mfloat-abi=softfp |          |
//    |          | -mfpu=fpv5-sp-d16                          |          |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -mcpu=cortex-m7 -mfloat-abi=softfp |          |
//    |          | -mfpu=fpv5-d16                             |          |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m -mfloat-abi=softfp |          |
//    |          | -mfpu=fpv5-d16                             |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-M7 | -mthumb -mcpu=cortex-m7 -mfloat-abi=hard   | armv7e-m |
//    |(Hard FP) | -mfpu=fpv5-sp-d16                          | /fpu     |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m -mfloat-abi=hard   |          |
//    |          | -mfpu=fpv5-sp-d16                          |          |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -mcpu=cortex-m7 -mfloat-abi=hard   |          |
//    |          | -mfpu=fpv5-d16                             |          |
//    |          |--------------------------------------------|          |
//    |          | -mthumb -march=armv7e-m -mfloat-abi=hard   |          |
//    |          | -mfpu=fpv5-d16                             |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-R4 | [-mthumb] -march=armv7-r                   | armv7-ar |
//    |Cortex-R5 |                                            | /thumb   |
//    |Cortex-R7 |                                            |          |
//    |(No FP)   |                                            |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-R4 | [-mthumb] -march=armv7-r -mfloat-abi=softfp| armv7-ar |
//    |Cortex-R5 | -mfpu=vfpv3-d16                            | /thumb   |
//    |Cortex-R7 |                                            | /softfp  |
//    |(Soft FP) |                                            |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-R4 | [-mthumb] -march=armv7-r -mfloat-abi=hard  | armv7-ar |
//    |Cortex-R5 | -mfpu=vfpv3-d16                            | /thumb   |
//    |Cortex-R7 |                                            | /fpu     |
//    |(Hard FP) |                                            |          |
//    |----------|--------------------------------------------|----------|
//    |Cortex-A* | [-mthumb] -march=armv7-a                   | armv7-ar |
//    |(No FP)   |                                            | /thumb   |
//    |----------|--------------------------------------------|----------|
//    |Cortex-A* | [-mthumb] -march=armv7-a -mfloat-abi=softfp| armv7-ar |
//    |(Soft FP) | -mfpu=vfpv3-d16                            | /thumb   |
//    |          |                                            | /softfp  |
//    |----------|--------------------------------------------|----------|
//    |Cortex-A* | [-mthumb] -march=armv7-a -mfloat-abi=hard  | armv7-ar |
//    |(Hard FP) | -mfpu=vfpv3-d16                            | /thumb   |
//    |          |                                            | /fpu     |
//    --------------------------------------------------------------------
