/**
 * Mock trends — structured for future scraping/API swap.
 * @returns {{ updatedAt: string, ideas: Array<{ title: string, niche: string, difficulty: string }>, sounds: Array<{ name: string, mood: string, note: string }> }}
 */
function getMockTrends() {
  return {
    updatedAt: new Date().toISOString(),
    source: 'mock',
    ideas: [
      { title: 'Day-in-the-life with a twist ending', niche: 'Lifestyle', difficulty: 'medium' },
      { title: '3 mistakes I stopped making (save this)', niche: 'Fitness', difficulty: 'easy' },
      { title: 'POV: you finally fixed your lighting', niche: 'Creator tips', difficulty: 'easy' },
      { title: 'Before/after but honest timeline', niche: 'Skincare', difficulty: 'medium' },
      { title: 'Storytime: the DM that changed everything', niche: 'Personal brand', difficulty: 'hard' },
      { title: 'Trending audio + your niche hook in 3s', niche: 'General', difficulty: 'easy' },
      { title: 'Green screen reaction to your niche drama', niche: 'Commentary', difficulty: 'medium' },
      { title: 'Checklist reel: 5 steps under 15s', niche: 'Education', difficulty: 'easy' },
      { title: 'Unpopular opinion (respectfully)', niche: 'Hot take', difficulty: 'medium' },
      { title: 'Replying to hate comments (kindly)', niche: 'Community', difficulty: 'hard' },
    ],
    sounds: [
      { name: 'Upbeat motivational clip', mood: 'hype', note: 'Good for fitness & morning routines' },
      { name: 'Lo-fi chill beat', mood: 'calm', note: 'Aesthetic vlogs & skincare' },
      { name: 'Comedic boing / punchline sting', mood: 'funny', note: 'Skits and reaction hooks' },
      { name: 'Soft piano build', mood: 'emotional', note: 'Storytime payoffs' },
      { name: 'Percussion-only rhythm', mood: 'trendy', note: 'Dance & transition cuts' },
    ],
  };
}

module.exports = { getMockTrends };
