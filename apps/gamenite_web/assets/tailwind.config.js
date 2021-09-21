const colors = require('tailwindcss/colors')

module.exports = {
  purge: [
    "../**/*.html.eex",
    "../**/*.html.leex",
    "../**/views/**/*.ex",
    "../**/live/**/*.ex",
    "./js/**/*.js"
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      blurple: {
        DEFAULT: '#5865F2',
        dark: '#404EED'
      },
      pink: {
        light: '#ff7ce5',
        DEFAULT: '#ff49db',
        dark: '#ff16d1',
      },
      gray: {
        darkest: '#23272A',
        dark: '#2C2F33',
        DEFAULT: '#99AAB5',
        light: '#F6F6F6',
      },

      black: colors.black,
      white: colors.white,
      indigo: colors.indigo,
      red: colors.rose,
      yellow: colors.amber,
    }
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
