const colors = require('tailwindcss/colors')

module.exports = {
  purge: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
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
        light: '#E5E5E5',
      },

      black: colors.black,
      white: colors.white,
      indigo: colors.indigo,
      red: colors.red,
      blue: colors.blue,
      yellow: colors.yellow,
      green: colors.green
    },
    screens: {
      'xs': '480px',
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
    },
    extend: {
      fontFamily: {
        'sans': ['Indie-Flower', 'Helvetica', 'Arial', 'sans-serif']
      }
    },
  },

  variants: {
    opacity: ({ after }) => after(['disabled']),
    extend: {},
  },
  plugins: [],
}
