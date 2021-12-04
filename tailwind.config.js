module.exports = {
    theme: {
      fontFamily: {
        sans: ['IBM Plex Sans'],
        header: ['Roboto']
      }
    },
    variants: [], // We can do variants in elm code
    plugins: [
        require("@tailwindcss/typography"),
        require("@tailwindcss/forms"),
        require("@tailwindcss/aspect-ratio")
    ],
    future: {
        removeDeprecatedGapUtilities: true,
    },
};
