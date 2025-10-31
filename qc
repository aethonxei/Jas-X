/*  Sticker Quote Plugin  
 *  Made by Aethonxei  
 *  Inspired by GataBot-MD  
 */

import { sticker } from '../lib/sticker.js'
import axios from 'axios'

const handler = async (m, { conn, args, command }) => {
    let text

    // 🧩 Get the text (from arguments or quoted message)
    if (args.length >= 1) {
        text = args.join(' ')
    } else if (m.quoted && m.quoted.text) {
        text = m.quoted.text
    } else {
        return conn.reply(m.chat, '📌 You forgot to include the text!', m)
    }

    if (!text) return conn.reply(m.chat, '📌 You forgot to include the text!', m)

    // 🔒 Check if the sender is an owner
    const senderNum = m.sender.split('@')[0]
    const owners = global.owner.map(([num]) => num.replace(/[^0-9]/g, ''))
    const isOwner = owners.includes(senderNum)

    // 🛑 If not owner, check if they mentioned an owner
    if (!isOwner) {
        const lowerText = text.toLowerCase()
        const mentioned = m.mentionedJid?.map(jid => jid.split('@')[0]) || []

        const mentionsOwner = owners.some(owner =>
            lowerText.includes(owner) ||
            lowerText.includes(`@${owner}`) ||
            mentioned.includes(owner)
        )

        if (mentionsOwner) {
            return conn.reply(
                m.chat,
                `🌸 *Ara ara~... Mentioning one of my creators?*  
✨ *How bold of you, onii-chan...*  
💢 *But I can’t betray my creators...*  
😈 *...unless you want to disappear with them~ 💀*`,
                m
            )
        }
    }

    // 🧑‍🎨 Identify the user mentioned or sender
    const who = m.mentionedJid && m.mentionedJid[0]
        ? m.mentionedJid[0]
        : m.fromMe
        ? conn.user.jid
        : m.sender

    // ✂️ Remove mention from text
    const mentionRegex = new RegExp(`@${who.split('@')[0].replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*`, 'g')
    const cleanText = text.replace(mentionRegex, '')

    if (cleanText.length > 40)
        return conn.reply(m.chat, '📌 The text cannot be longer than 40 characters.', m)

    // 🖼️ Get profile picture & name
    const pp = await conn.profilePictureUrl(who).catch(() => 'https://telegra.ph/file/24fa902ead26340f3df2c.png')
    const name = await conn.getName(who)

    // 🧱 Create the sticker quote object
    const obj = {
        type: 'quote',
        format: 'png',
        backgroundColor: '#000000',
        width: 512,
        height: 768,
        scale: 2,
        messages: [{
            entities: [],
            avatar: true,
            from: {
                id: 1,
                name: `${name}`,
                photo: { url: `${pp}` }
            },
            text: cleanText,
            replyMessage: {}
        }]
    }

    // 🪄 Generate the quote image using external API
    const { data } = await axios.post('https://bot.lyo.su/quote/generate', obj, {
        headers: { 'Content-Type': 'application/json' }
    })

    const buffer = Buffer.from(data.result.image, 'base64')

    // 🧾 Get sticker pack info
    const userId = m.sender
    const userData = global.db.data.users[userId] || {}
    const packName = userData.text1 || global.packsticker || 'Made by Aethonxei'
    const authorName = userData.text2 || global.packsticker2 || 'Aethonxei'

    // 🧷 Create and send sticker
    const stick = await sticker(buffer, false, packName, authorName)
    if (stick) return conn.sendFile(m.chat, stick, 'quote.webp', '', m)
}

handler.help = ['qc']
handler.tags = ['sticker']
handler.command = ['qc']
handler.group = true
handler.register = true

export default handler
