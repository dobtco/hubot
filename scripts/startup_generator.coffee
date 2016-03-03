`
/*  Web 2.0 Name Generator
    Written by Jacqueline "Kira" Hamilton (http://lightsphere.com/)

    Copyright 2006, 2007. All rights reserved.
*/

// retired: 23, 42, U
//
partA = new Array( "Babble", "Buzz", "Blog", "Blue", "Brain", "Bright", "Browse", "Bubble", "Chat", "Chatter", "Dab", "Dazzle", "Dev", "Digi", "Edge", "Feed", "Five", "Flash", "Flip", "Gab", "Giga",  "Inno", "Jabber", "Jax", "Jet", "Jump", "Link", "Live", "My", "N", "Photo", "Pod", "Real", "Riff", "Shuffle", "Snap", "Skip", "Tag", "Tek", "Thought", "Top", "Topic", "Twitter", "Word", "You", "Zoom");

partB = new Array( "bean", "beat", "bird", "blab", "box", "bridge", "bug", "buzz", "cast", "cat", "chat", "club", "cube", "dog", "drive", "feed", "fire", "fish", "fly", "ify", "jam", "links", "list", "lounge", "mix", "nation", "opia", "pad", "path", "pedia", "point", "pulse", "set", "space", "span", "share", "shots", "sphere", "spot", "storm",  "ster", "tag", "tags", "tube", "tune", "type", "verse", "vine", "ware", "wire", "works", "XS", "Z", "zone", "zoom" );

// these are not complete words:

partC = new Array( "Ai", "Aba", "Agi", "Ava", "Cami", "Centi", "Cogi", "Demi", "Diva", "Dyna", "Ea", "Ei", "Fa", "Ge", "Ja", "I", "Ka", "Kay", "Ki", "Kwi", "La", "Lee", "Mee", "Mi", "Mu", "My", "Oo", "O", "Oyo", "Pixo", "Pla", "Qua", "Qui", "Roo", "Rhy", "Ska", "Sky", "Ski", "Ta", "Tri", "Twi", "Tru", "Vi", "Voo", "Wiki", "Ya", "Yaki", "Yo", "Za", "Zoo" );

partD = new Array( "ba", "ble", "boo", "box", "cero", "deo", "del", "do", "doo", "gen", "jo", "lane", "lia", "lith", "loo", "lium", "mba", "mbee", "mbo", "mbu", "mia", "mm", "nder", "ndo", "ndu", "noodle", "nix", "nte", "nti", "nu", "nyx", "pe", "re", "ta", "tri", "tz", "va", "vee", "veo", "vu", "xo", "yo", "zz", "zzy", "zio", "zu");

lastName = new String();

function genName() {
    var rand = roll(2);
    var A = new String();
    var B = new String();

    if (rand == 0) {
        A = partA[ roll(partA.length) ];
        B = partB[ roll(partB.length) ];
    } else {
        A = partC[ roll(partC.length) ];
        B = partD[ roll(partD.length) ];
    }
    var name = A + B;
    return name;
}

function roll(num) {
    return Math.floor(Math.random() * num );
}
`

_ = require('underscore')
os = require('os')
request = require('request')
fs = require('fs')

module.exports = (robot) ->
  robot.hear /startup me/i, (msg) ->
    x_coord = _.sample([25, 370, 700])
    y_coord = _.sample([133, 363])
    thing = _.sample([
      "shirt",
      "fish",
      "laptop",
      "dog",
      "cat",
      "hammer",
      "bed",
      "mattress",
      "cd",
      "potato",
      "noodle",
      "guitar",
      "fish",
      "kiss",
      "veil",
      "structure",
      "tail",
      "passenger",
      "sheet",
      "carriage",
      "ground",
      "cough",
      "reason",
      "cub",
      "truck",
      "coat",
      "bomb",
      "mind",
      "gun",
      "waste",
      "rabbits",
      "secretary",
      "wren",
      "snakes",
      "needle",
      "reward",
      "back",
      "boundary",
      "sugar",
      "hydrant",
      "punishment",
      "oatmeal",
      "bear",
      "pen",
      "grain",
      "grandfather",
      "pie",
      "sound",
      "language",
      "attraction",
      "stove",
      "voyage",
      "screw",
      "error",
      "trains",
      "sea",
      "slip",
      "theory",
      "scarecrow",
      "steel",
      "stream",
      "taste",
      "week",
      "need",
      "geese",
      "voice",
      "quill",
      "care",
      "pocket",
      "fly",
      "poison",
      "summer",
      "turkey",
      "meeting",
      "selection",
      "pin",
      "eye",
      "train",
      "straw",
      "sheep",
      "partner",
      "toys",
      "jar",
      "chess",
      "mass",
      "popcorn",
      "oil",
      "level",
      "adjustment",
      "copper",
      "trip",
      "action",
      "decision",
      "mark",
      "payment",
      "spiders",
      "cow",
      "street",
      "interest",
      "top",
      "laborer",
      "feeling",
      "oranges",
      "dock",
      "lamp",
      "mist",
      "neck",
      "play",
      "reaction",
      "society",
      "crib",
      "school",
      "quince"
    ])

    msg.send "Alright, finding you a new portfolio company..."
    name = genName()
    logoPath = "#{os.tmpdir()}/#{name}.png"
    logoUrl = "https://withoomph.com/search/index?businessName=#{name}&searchTerm=#{thing}#search/1"
    apiKey = process.env.BROWSHOT_KEY
    url = "https://api.browshot.com/api/v1/screenshot/create?key=#{apiKey}&url=#{encodeURIComponent(logoUrl)}"
    console.log url
    request url, (err, res, body) ->
      id = JSON.parse(body).id
      setTimeout ->
        url = "https://api.browshot.com/api/v1/screenshot/thumbnail?id=#{id}&key=#{apiKey}&left=#{x_coord}&right=#{x_coord + 300}&top=#{y_coord}&bottom=#{y_coord + 200}&width=300&height=200"
        request url, (_err, _res, _body) ->
          setTimeout ->
            msg.send "Introducing... #{name}.\n#{url}"
          , 2000
      , 4000 # for first screenshot to complete
