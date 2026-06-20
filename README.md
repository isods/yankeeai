# YankeeAI Desktop — User Guide

This guide explains how to use the desktop app for sign-in, local models, file uploads, and collections (knowledge bases).

Download the latest version here: [YankeeAI_0.1.0_x64_en-US.msi](https://pub-cad9c2eac9c943378f065993063e6ab4.r2.dev/builds/27909292028/x86_64-pc-windows-msvc/YankeeAI_0.1.0_x64_en-US.msi)

### Windows Installation Warning

When installing on Windows, you may see a security warning stating that the publisher cannot be verified or the app is unsigned. This is expected for development builds.

**To proceed with installation:**
1. Click **"More info"** in the Windows SmartScreen warning
2. Click **"Run anyway"** to continue with the installation

The app is safe to install - this warning appears because the build is not yet signed with a trusted certificate.

---

# Version v1.0.0(current)

This section describes the **current version** (build date: after 01 Jun 2026 00:31:41 EDT).

## What’s new (since v0.0.1)

| Feature                                | What it does                                                                     | Where to find it                            |
| -------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------- |
| **Native GGUF chat**                   | Run local GGUF models directly via llama-cpp-python (no Ollama required).        | **Tools → My Models** (native models)       |
| **Native model generation parameters** | Configure temperature, top P, top K, min P, and system prompt for native models. | **Tools → My Models** → model settings      |
| **RAG architecture switch**            | Choose between **Simple RAG** and **Agent RAG** retrieval pipeline behavior.     | **Tools → My Models** / model settings area |
| **RAG retrieval settings**             | Override retrieval settings (Top K / Context K) per conversation.                | Chat page toolbar → **Retrieval settings** (layers icon)    |
| **Multimodal model detection**         | Automatically detect vision capabilities from HuggingFace metadata.              | **Tools → Model Browser**                   |

## Native GGUF chat

The app now supports running GGUF models directly via llama-cpp-python, without requiring Ollama.

1. Open **Tools → My Models**.
2. Switch to the **Native** tab to see installed GGUF models.
3. Download GGUF models from **Tools → Model Browser** (HuggingFace source).
4. Select a native model as your active model for chat.

## RAG architecture switch

Choose how the app retrieves context from your files:

- **Simple RAG**: Single-step retrieval. Fetch top K chunks, include up to Context K in the prompt.
- **Agent RAG**: Use the LangGraph retrieval pipeline (current default behavior).

Found in: **Tools → My Models** → model settings area.

## RAG retrieval settings (per-chat)

Override global retrieval settings for a specific conversation:

1. In any chat, click the **Retrieval settings** (layers) icon in the chat toolbar.
2. Adjust **Top K** (chunks retrieved) and **Context K** (chunks included in prompt).
3. Settings apply only to this conversation.

---

# Dev version v0.0.1 (build: 01 Jun 2026 00:31:41 EDT)

## What’s new (since initial release)

| Feature                                   | What it does                                                                                            | Where to find it                                                               |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Web search in chat**                    | Lets the assistant search the web and cite sources in the response.                                     | Chat page toolbar (toggle / globe), and sources shown under assistant messages |
| **Link library + scraping**               | Save links, select one or more, scrape readable content, and attach it as context to your next message. | Chat header / toolbar → **Link library**                                       |
| **Better citations + Sources UI**         | Answers can show clickable inline citations like `[1]` and a **Sources** section under messages.        | Under assistant messages in chat                                               |
| **Image support (vision models)**         | Attach images (and paste from clipboard) and chat with a vision-capable model.                          | Chat prompt attachments; paste with Cmd/Ctrl+V                                 |
| **Embedding model management + re-index** | Switch the embedding model used for file indexing and re-index all uploaded files.                      | **Settings → Files & Storage**                                                 |

## Web search in chat

1. Open any chat.
2. Enable **Web search** in the chat toolbar.
3. Ask your question.
4. After the assistant responds, check the **Searched the web** section under the message for the list of sources.

Notes:

- If you attach images and your local model supports vision, the app may derive better web queries from the image content.
- Web sources open in your system browser.

## Link library (scrape links into context)

Use this when you want the assistant to answer from one or more web pages.

1. In chat, open **Link library**.
2. In **Add a link**, enter a URL and a title, then click **Save link**.
3. Select one or more saved links.
4. (Optional) Enable **Discover sub-pages when scraping** and adjust **Max depth** / **Max pages**.
5. Click **Scrape selected**.
6. When you see **Link context ready**, send your next message. The scraped text will be included as context.

Tip:

- If a page can't be scraped (JS-heavy sites, blocked bots), try opening it externally and using another source.

## Images in chat (vision)

You can include images in two ways:

1. Click the image/file attachment control and choose an image file.
2. Paste an image with Cmd/Ctrl+V.

Important:

- Image understanding requires a **vision-capable** model (for Ollama, the UI will warn if the current model does not support vision).

## Embedding model & re-index (desktop)

1. Open **Settings → Files & Storage**.
2. Choose an **Embedding Model**.
3. Click **Apply & Re-index**.
4. Confirm the switch.

Re-indexing status is shown with a progress bar.

---

## 1. Log In

YankeeAI Desktop supports **guest use** (local chat without an account) and **signed-in use** (synced account, cloud features, and profile).

### Sign in

1. Open the app. If you are not signed in, the sidebar shows **Sign In** at the bottom.
2. Click **Sign In**. Your default browser opens to the login page.
3. A notification appears: **Waiting for browser sign in**. Complete login in the browser:
   - Use **Google**, or
   - Sign in with **email and password** if you already have an account.
4. If you already have a web session, you may be asked to confirm using that account for the desktop app.
5. After success, the browser shows a confirmation page and the app focuses again. You are taken to **Chat**, and a success message is shown.

Your credentials are handled securely: tokens are stored locally by the app backend (sidecar), not in the browser redirect URL.

### Cancel sign-in

While the waiting notification is visible, click **Cancel** to stop the attempt. You must start **Sign In** again if you change your mind.

If sign-in takes too long (about 5 minutes), it times out automatically. Check your internet connection and try again.

### Sign out

1. Click your **profile** at the bottom of the sidebar.
2. Choose **Log out**.

You return to guest mode and can continue using local features where available.

### Troubleshooting login

| Issue                                           | What to try                                                                                        |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Browser does not open                           | Check network connection; quit and restart the app.                                                |
| Login succeeds in browser but app stays waiting | Bring the desktop app to the front; if needed, restart the app (deep link may resume the session). |
| **Login Error** toast                           | Confirm the app backend is running and you are online.                                             |

---

## 2. Pull a Model and Use It

Local chat uses **Ollama** on your machine. You must install Ollama, connect the app to it, download at least one model, then select it for chat.

### Step A — Install and connect Ollama

1. Open **Tools** (wrench icon in the sidebar) → **Configure Local Ollama**, or use the setup prompt when you first choose Ollama as a provider.
2. On the **Installation** tab, follow the steps for your OS (macOS, Windows, or Linux).
3. On the **Setup** tab:
   - Confirm **Operating System** and **Port** (default `11434`).
   - Click **Test Connection**. Wait for **Connected**.
4. If models already appear under **Select Active Model**, pick one and click **Save & Close**.

### Step B — Pull (download) a model

1. Open **Tools** → **Model Browser** (or **Open Model Browser** from the Ollama setup dialog).
2. Choose a source:
   - **HuggingFace Hub** — search GGUF models; pick a **quantization** (e.g. `Q4_K_M`) before pulling.
   - **Ollama Library** — browse official Ollama models.
3. Filter by type if needed: **Chat / Text Gen** or **Embedding**.
4. Click **Pull** on a model. Progress is shown while the download runs (this can take minutes and uses disk space).
5. When the pull finishes, **Use Model** appears. Click it to set that model as your active Ollama model for chat.

You can also pull from the terminal (Ollama must be running):

```bash
ollama pull llama3.2:3b
```

### Step C — Use a model in chat

- After **Use Model**, new messages use that model automatically.
- To change the model anytime:
  - **Tools** → **Model Browser** → **Use Model** on another downloaded model, or
  - **Tools** → **My Models** to see everything installed locally, or
  - Chat toolbar → **Model & provider settings** (gear) → pick provider **Ollama** and the model.

### My Models page

**Tools** → **My Models** lists all models Ollama has on disk. You can:

- Search and sort the list
- **Test** a model with a short prompt
- Adjust **temperature**, **top P**, **top K**, **min P**, and **system prompt** per model
- **Delete** a model to free disk space

### Embedding models (for collections)

Collections need a separate **embedding** model (not the same as your chat model). When you create a collection, only embedding models **already on your device** are offered. Pull embedding models via **Model Browser** (filter **Embedding**) or install them through collection import flows when prompted.

---

## 3. File Ingesting

The app can read your documents and use them as context in chat. Open the knowledge UI from the **folder** icon in the chat toolbar (**My Files**).

### Supported file types

| Type        | Extensions           |
| ----------- | -------------------- |
| Documents   | PDF, DOC, DOCX, PPTX |
| Text / data | TXT, MD, CSV, JSON   |

**Maximum file size:** 100 MB per file.

Unsupported types show a warning and are skipped.

### Attach files in chat

1. On a **new chat** or an **existing chat**, click the **paperclip** next to the message box.
2. Select one or more supported files.
3. Files are uploaded and processed. A progress indicator may appear while processing runs.
4. Attached files show as chips above the input. Send a message to start the chat (new chat) or continue the conversation.

**Tips:**

- You can attach files **before** typing your first message on the welcome screen.
- **Paste** supported files from the clipboard where the app allows it.
- For **images** (JPG, PNG, GIF, WebP), use a **vision-capable** Ollama model (e.g. LLaVA, Gemma 3 vision). The attach control explains if your current model does not support images.

### My Files (global uploads)

1. Click the **folder** icon in the chat header → **My Files**.
2. Open the **Files** tab.
3. Use **Upload** to add files to your personal knowledge base (not tied to a collection yet).
4. Select rows and click **Add context** to attach them to a **new chat** on the home screen.
5. Use **Delete** to remove files you no longer need.

Uploaded files are indexed for search. Processing status is tracked per file (`pending`, `processing`, `completed`, `failed`).

### File context in conversations

When files are attached, the app enables **file context** for that conversation so answers can cite relevant passages. If you attach files from **My Files** or a **collection**, context stays on until you remove the attachments.

To re-index all global files after changing the default embedding model, go to **Settings** → **Files** (desktop) and run **Re-index** with the new model.

---

## 4. Collection Operations

A **collection** is a named group of files that share one **embedding model**. The app builds a vector index so chat can retrieve the most relevant chunks across those files.

Manage collections in **My Files** → **Collections** tab.

### Create a collection

1. Open **My Files** → **Collections**.
2. Click **New**.
3. Enter a **name** and optional **description**.
4. Choose an **embedding model** (only models already on this device are listed):
   - **Ollama (local)** — e.g. `nomic-embed-text`
   - **Hugging Face (cached)** — models already downloaded on the machine
5. Click **Create**.

If no embedding model is available, pull one from **Model Browser** (type **Embedding**) or complete the install steps when importing an archive.

### Add files to a collection

1. In **Collections**, click a collection **name** to open it.
2. Click **Upload** and choose supported files (same types as in [File ingesting](#3-file-ingesting)).
3. Wait for uploads to finish. The file list refreshes with processing status.

You can also upload into a collection from the global **Files** tab by filtering and assigning where the UI allows.

### Chat with a collection

- From the collection list: click the **chat** icon on a row (**Chat with collection**). Requires at least one file.
- Inside a collection: click **Chat with all** to attach every file in that collection to a new chat.

You are taken to the chat screen with a **collection card** showing the name, file count, and embedding model. Send a message to ask questions across the whole collection.

To use only **some** files: open the collection, select rows, and use **Add context** (same as global files).

### Rename, export, and delete

| Action     | How                                                                                                               |
| ---------- | ----------------------------------------------------------------------------------------------------------------- |
| **Rename** | Pencil icon on the collection row → edit name → confirm                                                           |
| **Export** | Download icon → saves a ZIP to **Downloads** (`<name>_collection.zip`) with manifest, vectors, and original files |
| **Delete** | Trash icon → click again to confirm. Removes the collection and its indexed data                                  |

### Import a collection

**Import** accepts a ZIP export from this app (or a compatible archive).

1. Click **Import** on the Collections tab and choose a `.zip` file.
2. **Standard export (with manifest):**
   - The app reads `manifest.json`, checks embedding model and files.
   - If some files are missing from the ZIP, you can continue with a warning or cancel.
   - If a collection with the same embedding model and overlapping content exists, you may **merge**, **import as copy**, or **cancel**.
   - If the embedding model is not installed, you are prompted to **pull** (Ollama) or **download** (Hugging Face) before import finishes.
3. **Raw Chroma archive (no manifest):**
   - A guided dialog asks for collection name, description, and embedding model.
   - Install the embedding model if needed, then the app restores vectors and files.

### Supply missing raw files

After import, some entries may show as missing originals (`has_raw_file` false). Inside the collection:

- **Supply files** — upload a ZIP that contains the missing originals, matched by name/hash, or
- Per-row action to supply a single raw file.

This is only needed when vectors were imported but binary originals were not in the export.

### Collections vs. chat attachments

|                 | **Global file (Files tab)**      | **Collection**                                |
| --------------- | -------------------------------- | --------------------------------------------- |
| Embedding model | App default (Settings → Files)   | Fixed at collection creation                  |
| Best for        | One-off documents, mixed uploads | Persistent knowledge base, many related files |
| Attach to chat  | Select files → **Add context**   | **Chat with collection** or select subset     |

### Troubleshooting collections

| Issue                               | What to try                                                                                                                 |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Collection is empty** for chat    | Upload at least one file and wait until processing completes.                                                               |
| Import fails                        | Use a valid export ZIP; check embedding model id matches an installed model.                                                |
| Wrong answers from collection       | Confirm you started chat via **Chat with collection** and the embedding model matches the one used when files were indexed. |
| Pull / download during import stuck | Ensure Ollama is running (for `ollama:…` models) or wait for Hugging Face cache download on first use.                      |

---

## Quick reference

| Goal                                | Where to go                                              |
| ----------------------------------- | -------------------------------------------------------- |
| Sign in                             | Sidebar → **Sign In**                                    |
| Install Ollama                      | **Tools** → setup modal → **Installation**               |
| Download a chat model               | **Tools** → **Model Browser** → **Pull** → **Use Model** |
| Manage installed models             | **Tools** → **My Models**                                |
| Upload a file for one chat          | Chat → **paperclip**                                     |
| Manage all files & collections      | Chat header → **folder** → **My Files**                  |
| New collection                      | **My Files** → **Collections** → **New**                 |
| Ask questions over a knowledge base | **Collections** → **Chat with collection**               |

For technical details on auth and file processing architecture, see [desktop/auth-telemetry.md](./desktop/auth-telemetry.md) and [frontend/chat_with_files_workflow.md](./frontend/chat_with_files_workflow.md).
