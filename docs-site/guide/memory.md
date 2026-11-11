# Memory and knowledge

Bots remember what matters about you and your work, so you don't repeat yourself: something you
tell a bot in one chat, it can recall in the next. Knowledge is different: it's documents you give
a bot, such as files, a website or a GitHub repository, that it searches and cites when they're
relevant.

| | Memory | Knowledge |
| --- | --- | --- |
| What it holds | Short notes: facts, preferences, summaries of past work | Your documents, split into passages |
| Where it comes from | The bot writes it as you chat | You add sources; Kasama reads them |
| How the bot uses it | The most relevant notes are in every run | The bot searches it when a question calls for it, and cites the source |
| Where to manage it | **Memory** | **Bot settings** → **Knowledge** |

## What bots remember

Each bot has its own memory; bots never read each other's. A memory is one of these kinds:

| Kind | What it is |
| --- | --- |
| **Fact** | Something true about you, your work or the people you work with. |
| **Preference** | How you like things done, such as a writing style or a format. |
| **Episode** | A summary of an earlier part of a long conversation. |
| **Summary** | A summary of past work. |

Memories are written three ways:

- **After every run**, the bot's cheap model reads the latest exchange and saves up to 10 lasting
  facts and preferences. Small talk and one-off requests are skipped.
- **When you ask**, the bot saves a memory itself ("remember that I'm in America/Chicago"). Saving
  a memory never needs your approval, whatever the bot's autonomy.
- **When a chat gets long**, older messages are summarized once the conversation passes 70% of the
  model's context window, and the summary is saved as an episode.

A new memory that says nearly the same thing as an existing one updates it instead of adding a
copy. Without embeddings, only exact duplicates are caught.

### How bots recall

At the start of every run, the bot gets the 8 memories most relevant to your message, plus every
pinned memory. Kasama finds them by meaning and by matching words together.

Matching by meaning needs embeddings, which use the workspace's first OpenAI API key. Without one,
recall matches words only. ChatGPT plan sign-in doesn't provide embeddings.

## View and edit memory

1. Open a bot's chat and select **More** (the **…** button) → **Memory**. You can also open it
   from **Bot settings** → **Memory**.
2. Each memory shows its kind. Open a memory's menu for:
   - **Pin** or **Unpin**: pinned memories are always in the bot's context.
   - **Edit**: change the text. The bot uses the new version the next time it's relevant.
   - **Delete**: the memory is gone for good.

You can't add a memory from this screen. To add one, tell the bot in chat, or import memories
(below).

From the CLI:

```sh
kasama memory list Ada
kasama memory list Ada --search "timezone"
```

## Import memories from ChatGPT or Claude

If ChatGPT or Claude already knows you, bring that over.

1. Open the bot's **Memory** screen and select the import button
   (**Import memories from ChatGPT or Claude**).
2. **Copy** the prompt into ChatGPT or Claude, then paste its answer under **Its answer** and
   select **Next**.
3. Kasama turns the answer into facts and preferences. Untick anything that's wrong, then select
   **Save**.

Only people who manage the bot can import memories. See
[Templates, sharing and import](/guide/sharing) for importing whole agents.

## Where memory is kept

By default, memory lives in your Kasama database. Workspace owners and admins can keep it in
Honcho or Supermemory instead, with the workspace's
own account. The memory screen, data export and account deletion work the same either way.

1. Go to **Settings** → **Workspace settings** → **Where memory is kept**.
2. Pick **Supermemory** or **Honcho** and paste the **API key**.
3. Optional: for Honcho, a **Honcho workspace** (leave empty to use one made for this Kasama
   workspace). For a self-hosted Honcho or Supermemory, its **Server address**.
4. Turn on **Copy current memories over** to bring every bot's memories along, pinned ones
   included.
5. Select **Save**. Kasama checks the connection before saving.

To go back, open the same sheet and choose **Use built-in memory again**. Memories saved in the
provider stay there, and built-in memories were never removed.

::: warning Honcho deletes
Honcho can't delete a single message, so deleting a memory there hides it instead of erasing it.
Deleting your account deletes each bot's whole Honcho session.
:::

## Add knowledge

Give a bot documents to search and it answers from them and names the source.

1. Open **Bot settings** → **Knowledge**, then **Add knowledge**.
2. Choose what to add:
   - **Files**: select **Choose files** and pick PDF, Word (`.docx`), Markdown, HTML, CSV or text
     files, up to 50 at a time.
   - **Website**: enter the **Website address**. Kasama reads up to 50 pages on the same site.
   - **GitHub**: paste a **GitHub link** to a repository. Kasama reads up to 300 of its Markdown,
     text, HTML and CSV files.
3. Workspace owners and admins can turn on **Share with every bot in the workspace**.
4. Select **Add**.

Sources are read within about a minute. Each one shows **Waiting to be read**, **Reading…**, the
number of documents and passages, or **Couldn't read it**. Use **Sync now** to read a source again,
or **Delete** to remove it.

Website crawls follow the site's `robots.txt` and identify as `KasamaBot`. Private repositories use
the workspace's `GITHUB_TOKEN` secret (allowed for `api.github.com`). See
[Apps and connections](/guide/connections).

### How knowledge stays current

- Uploaded files are read once.
- Websites and repositories refresh daily.
- A source that fails is retried in 6 hours. One unreadable file is reported without stopping the
  rest.

### How bots use knowledge

When a question calls for it, the bot searches its own sources and the workspace's shared ones,
using the same meaning-and-words search as memory. Results come back as numbered passages with the
document, where in it (a heading, a page, or rows of a CSV) and a link, and the bot is asked to
cite them. In the chat, the search step lists the sources it used.

Everyone who can chat with a bot shares its knowledge, because sources belong to the bot or the
workspace, not to a person. Only the bot's managers can change its sources, and only admins can
change shared ones.

## Encryption

With encryption at rest turned on, memories and knowledge passages are encrypted before they're
stored. Search then matches by meaning, not exact words in encrypted text. See
[Privacy and security](/guide/privacy).

## Limits

- **Scanned PDFs** and PDFs with unusual font encodings give little or no text; that file shows
  **Couldn't read it**.
- **Connection sources** (indexing what a connected app such as Notion or Google Drive returns)
  work through the API only (`POST /v1/knowledge-sources` with `kind: connection`). Changes in the
  app are picked up by the daily refresh, not right away.
- The app can't change a website's page limit. Through the API, `max_pages` goes up to 200.
- Honcho and Supermemory catch only exact duplicate memories, not near-duplicates. Memories can't
  be moved back from a provider to built-in memory.
- Search in the chat shows sources on the search step, not as a separate list under the reply.

## Related

- [Chatting with a bot](/guide/chat)
- [Templates, sharing and import](/guide/sharing)
- [Privacy and security](/guide/privacy)
- [Bots and models](/guide/bots)
