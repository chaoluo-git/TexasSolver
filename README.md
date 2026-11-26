
# :rotating_light: This project still works but a more than 20x faster new GPU version is available here: [TexasSolverGPU](https://bupticybee.github.io/texassolver_gpu_page)

# CPP Texas Solver

[![release](https://img.shields.io/github/v/release/bupticybee/TexasSolver?style=flat-square)](https://github.com/bupticybee/TexasSolver/releases)
[![license](https://img.shields.io/github/license/bupticybee/TexasSolver?style=flat-square)](https://github.com/bupticybee/TexasSolver/blob/master/LICENSE)
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/bupticybee/TexasSolver/blob/console/TexasSolverTechDemo.ipynb)
[![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://gitter.im/TexasSolver/TexasSolver)

README [English](README.md) | [中文](README.zh-CN.md)

## Introduction 
A open sourced, extremely efficient Texas Hold'em and short deck solver. See this [Introduction video](https://youtu.be/IsSJNz7sRmQ) for more. Supports Windows,MacOs and Linux.

![](imgs/solver_example.gif)

Features:

- In a tree with 1~2bets + allin, it's speed exceeds piosolver on flop
- Support Mac, Linux and Windows
- Support texas holdem and shortdeck
- Support cross language calls
- Result aliged with piosolver
- Support dump strategy to json file
- It's the c++ version of [TexasHoldemSolverJava](https://github.com/bupticybee/TexasHoldemSolverJava) with a ton of optimization, it's 5x faster than the java version and takes less than 1/3 memory.

Feel free to mess with a toy solver [in google colab](https://colab.research.google.com/github/bupticybee/TexasSolver/blob/console/TexasSolverTechDemo.ipynb)


## Install

Download package according to your OS in [release package](https://github.com/bupticybee/TexasSolver/releases), unzip it, and install is done. It's that simple.

### Development builds

The `dev` branch starts from this fork's default branch, `master`. Each push to `dev` starts the [Dev builds and release workflow](https://github.com/chaoluo-git/TexasSolver/actions/workflows/dev-release.yml). Once all three builds succeed, it publishes a [GitHub prerelease](https://github.com/chaoluo-git/TexasSolver/releases) tagged `dev-<run_number>-<short_sha>`.

| Platform | Download |
| --- | --- |
| Mac with Apple Silicon | `TexasSolverGui-macos-arm64.dmg` |
| Mac with an Intel processor | `TexasSolverGui-macos-x64.dmg` |
| Windows x64 | `TexasSolverGui-windows-x64.zip` |

Compare the download's SHA-256 hash with the value in `SHA256SUMS.txt` attached to the same release. On macOS, open the DMG and copy `TexasSolverGui.app` to Applications. The app uses an ad hoc signature and has no Apple notarization, so Gatekeeper may block it. On Windows, extract the entire ZIP and run `TexasSolverGui.exe` from the extracted folder.

### Build from source

On macOS, install Homebrew and the Xcode Command Line Tools, then run the commands below.

```bash
brew install qt@5 libomp
./build-macos.sh
```

The script produces `build-mac/TexasSolverGui.app` and `build-mac/TexasSolverGui.dmg` for the host architecture. Set `QT_DIR` to the Qt installation directory when using a Qt 5 distribution other than Homebrew.

On Windows, install Qt 5.15.2 for MinGW x64 and its matching MinGW 8.1.0 x64 toolchain. Run the following in PowerShell, adjusting the paths to match your installation.

```powershell
./build-windows.ps1 -QtDirectory 'C:\Qt\5.15.2\mingw81_64' -MinGWDirectory 'C:\Qt\Tools\mingw810_64'
```

The script produces `dist/TexasSolverGui-windows-x64.zip`.

## GUI version Usage

After install the solver, double click the application binary (TexasSolverGui.exe in windows or TexasSolverGui.app in MacOS) to run TexasSolver.

## Console version Usage

Please check [console version document](https://github.com/bupticybee/TexasSolver/tree/console#usage) for more.

## Speed benchmark with piosolver

Piosolver and my TexasSolver(console version) run use the same settings (spr=10,flop game) and their result are aligned.

|                                | Input config                                              | log                                                          | thread number | memory usage | accuracy | converge time |
| ------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------ | ------------- | ------------ | -------- | ------------- |
| piosolver 1.0                  | [config_piosolver](benchmark/benchmark_piosolver.txt)     | [log_piosolver](benchmark/benchmark_outputs/piosolver_log.txt) | 6             | 492Mb        | 0.29%    | 242s          |
| TexasSolver 0.1.0 (Our solver) | [config_texassolver](benchmark/benchmark_texassolver.txt) | [log_texassolver](benchmark/benchmark_outputs/texassolver_log.txt) | 6             | 1600Mb       | 0.275%   | 172s          |

The compare image of their results is  [here](benchmark/benchmark_outputs/result_compair.png). As you can see their result are very close.

# License

[GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.en.html)

This software is licensed to person/business here: 
 [licensed_list](licensed_list.txt)

# Email

icybee@yeah.net

# Q & As

1. Q: Is the solver really free?
   - A: Yes, for personal users, the solver is completely opensourced and free.

2. Q: Can I upload it to other websites or forums? Can I share it with my friend?
   - A: No, you can only put the link of this project to other website, not the binary, this project is under AGPL-V3 license, and these kind of actions violates this license.

3. Q: Can I integrate it to my software?
   - A: If you integrate the release package (binary) into your software, Yes, you can do that. If you want to integrate the code of the solver into your software or provide service through internet, then you need to contact me for a commercial license, which is also the main profit-making method of this project.

4. Q: What framework do you use to write the ui?
   - A: I use QT 5.1.0 (opensourced edition) to build the GUI version. For the console version, I use Mingw + CMake.

