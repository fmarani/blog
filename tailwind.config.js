/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './hugosite/layouts/**/*.html',
    './hugosite/content/**/*.md',
    './posts/**/*.md',
    './til/**/*.md',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#15803d', // green-700
          dark: '#166534',    // green-800
          light: '#dcfce7',   // green-100
          lighter: '#f0fdf4', // green-50
        }
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            '--tw-prose-headings': theme('colors.primary.DEFAULT'),
            '--tw-prose-links': theme('colors.primary.dark'),
            '--tw-prose-code': theme('colors.slate.900'),
            a: {
              '&:hover': {
                color: theme('colors.primary.DEFAULT'),
              },
            },
          },
        },
      }),
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
