/*
 After you have changed the settings at "Your code goes here",
 run this with one of these options:
  "grunt" alone creates a new, completed images directory
  "grunt clean" removes the images directory
  "grunt responsive_images" re-processes images without removing the old ones
*/

module.exports = function(grunt) {

  grunt.initConfig({
    responsive_images: {
      dev: {
        options: {
          engine: 'gm',
          sizes: [{
            name: "1600",
            width: 1600,
            suffix: "_large_2x",
            quality: 30
          },{
            rename: false,
            name: "default",
            width: 800,
            suffix: "",
            quality: 30
          }]
        },

        /*
        You don't need to change this part if you don't change
        the directory structure.
        */
        files: [{
          expand: true,
          src: ['**/*.{gif,jpg,png}'],
          cwd: '/home/ubuntu/website/docroot',
          dest: '/home/ubuntu/website/images'
        }]
      }
    },

    /* Clear out the images directory if it exists */
    clean: {
      dev: {
        src: ['/home/ubuntu/website/images'],
        options: {force: true}
      }
    },

    /* Generate the images directory if it is missing */
    mkdir: {
      dev: {
        options: {
          create: ['/home/ubuntu/website/images']
        }
      }
    },

    /* Copy the "fixed" images that don't go through processing into the images/directory */
    copy: {
      skipped_images: {
        files: [{
          expand: true,
          cwd: '/home/ubuntu/website/docroot',
          src: ['**/*.{gif,jpg,png}'],
          filter: function(filepath) {
//           		console.log('filepath: ' + filepath);
          		// replace images_fixed with images
          		var pos = filepath.indexOf('/home/ubuntu/website/docroot');
//           		console.log('pos: ' + pos);
          		if (pos > -1) {
                    pos = pos + ('/home/ubuntu/website/docroot'.length);
          			var newPath = "../images";
           			console.log('newpath: ' + newPath);
          			newPath = newPath + filepath.substring(pos);
           			console.log('newpath: ' + newPath);
          			var exists = require('fs').existsSync(newPath);
                    console.log('exists [' + newPath + ']: ' + exists);
					if (exists)
						console.log (filepath);
					else
						console.log (filepath + ': copying...');
          			return !exists;
          		}
        		return false;
      	  },          
      	  dest: '../images/'
        }]
      }
    },
    watch: {
//     	files: [{
//           expand: true,
//           src: ['**/*.{gif,jpg,png}'],
//           cwd: 'images_src/',
//           dest: 'images/'
//         }],

/*      files: ['<%= responsive_images.dev.files %>'], */
		files: ['/home/ubuntu/website/docroot/**/*.{gif,jpg,png}'],
		tasks: ['responsive_images'],
        options: {
            spawn: false,
            event: ['all'],
        }
    }
  });
  
  grunt.loadNpmTasks('grunt-responsive-images');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-mkdir');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.registerTask('default', ['clean', 'mkdir', 'responsive_images', 'copy']);

};
