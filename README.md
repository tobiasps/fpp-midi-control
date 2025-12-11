# FPP MIDI Control

This project connects MIDI input on macOS to [Hammerspoon](https://www.hammerspoon.org/), which then controls a Falcon Player (FPP) or other targets via Lua scripts.

It is designed to work with a virtual MIDI port named `MidiToFPP` using macOS’s IAC Driver.

---

## Requirements

- **macOS**:  
  - Tested on recent macOS versions (e.g. Ventura / Sonoma).  
  - Requires access to:
    - **Audio MIDI Setup** (built into macOS)
    - **Security & Privacy**: You may need to grant accessibility / automation permissions for Hammerspoon.

- **Hammerspoon**:
  - Version: any relatively recent stable version (0.9.x or newer is recommended).
  - Hammerspoon configuration directory:
    - `~/.hammerspoon/`
  - Your main config file:
    - `~/.hammerspoon/init.lua` (this repository provides one or parts of it).

---

## Installing Hammerspoon

1. **Download Hammerspoon**

   - Go to:  
     https://www.hammerspoon.org/
   - Download the latest release `.zip`.
   - Unzip and move `Hammerspoon.app` to your `Applications` folder.

2. **First Launch & Permissions**

   - Open `Hammerspoon.app`.
   - macOS may warn that the app is downloaded from the internet:
     - Click **Open** (or go to `System Settings → Privacy & Security` and allow it).
   - Hammerspoon will likely ask for:
     - **Accessibility** permissions
     - Possibly **Automation** permissions
   - Grant these in:
     - `System Settings → Privacy & Security → Accessibility`
     - (And `Automation` if prompted)

3. **Configure the Hammerspoon Script**

   - Create or edit the file:
     - `~/.hammerspoon/init.lua`
   - Copy the Lua configuration from this project into that file (or merge it with your existing config).
   - Reload Hammerspoon config:
     - Click the Hammerspoon menu bar icon
     - Choose **Reload Config** (or use the hotkey if you have one configured).

---

## Setting Up the IAC “MidiToFPP” Port on macOS

This project expects a virtual MIDI input port called `MidiToFPP` using the macOS **IAC Driver**.

### 1. Open Audio MIDI Setup

- Open the app:
  - Press `Cmd + Space`, type `Audio MIDI Setup`, press Enter.
- In the menu bar, enable the MIDI Studio window:
  - `Window → Show MIDI Studio` (if it’s not already visible).

### 2. Enable the IAC Driver

- In the **MIDI Studio** window, look for an icon named **IAC Driver**.
- If you don’t see it, you may need to:
  - `Window → Show MIDI Studio` again or
  - Zoom / expand the window.
- Double-click the **IAC Driver** icon to open its properties.
- Check **“Device is online”**.
- Click **Apply** (if available).

### 3. Create the `MidiToFPP` Port

Inside the IAC Driver properties window:

1. Under **Ports**:
   - If there is an existing port you want to keep, leave it.
   - Otherwise, you can add a new one specifically for this project.

2. To add the port:
   - Click the **“+”** button under the ports list to add a new port.
   - Set the port name to exactly:
     - `MidiToFPP`  
       (case-sensitive if your script expects an exact match)

3. Confirm that:
   - **Device is online** is still checked.
   - The **Ports** list includes `MidiToFPP`.

4. Close the window.

### 4. Verify the Port

- In **Audio MIDI Setup → MIDI Studio**, the **IAC Driver** should be:
  - Online
  - Showing at least one port named `MidiToFPP`.
- In any MIDI-capable app (DAW, controller software, etc.), you should now see a MIDI output named `MidiToFPP`.

---

## Connecting Your MIDI Source

1. **Configure your MIDI controller / software**:
   - Set its MIDI output to the virtual port:
     - `MidiToFPP`

2. **Confirm Hammerspoon is listening**:
   - Ensure `Hammerspoon.app` is running.
   - Ensure `init.lua` (from this project) is active and loaded without errors:
     - Use **Hammerspoon → Console** from the menu bar to check for Lua errors.

3. **Trigger some MIDI notes / CC messages**:
   - Your MIDI controller or software should send data to `MidiToFPP`.
   - The Hammerspoon script should react according to how it’s written (e.g. mapping certain notes/CCs to FPP actions).
   - NOTE: Make sure the midi software (e.g. Logic, Ableton, or other) does create a MIDI loop. In other words it should be set to _not_ use `MidiToFPP` as an input, only output.

---

## Configuration Overview (Project-Specific)

- **Main script**:
  - `~/.hammerspoon/init.lua`  
  - Contains:
    - MIDI port binding (to `MidiToFPP`)
    - Mapping from MIDI events to actions (e.g. HTTP requests to FPP, scene changes, etc.)

- **Expected MIDI Port Name**:
  - `MidiToFPP`  
  - If you change this:
    - Update both:
      - The IAC port name in Audio MIDI Setup
      - The corresponding configuration / string in `init.lua`.

---

## Troubleshooting

- **`MidiToFPP` does not appear in other apps**:
  - Re-open **Audio MIDI Setup → MIDI Studio → IAC Driver**.
  - Ensure **Device is online** is checked.
  - Confirm a port named `MidiToFPP` exists.
  - Restart any MIDI apps that were open before you created the port.

- **Hammerspoon shows errors on reload**:
  - Open **Hammerspoon → Console**.
  - Check for Lua syntax errors or missing dependencies.
  - Fix issues in `init.lua` and reload.

- **No response to MIDI actions**:
  - Verify that:
    - Your controller/software is sending to `MidiToFPP`.
    - Hammerspoon is running.
    - The MIDI mapping in `init.lua` matches the messages being sent (channels, notes, CC numbers, etc.).
