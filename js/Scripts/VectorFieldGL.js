// Generated by CoffeeScript 1.10.0
(function() {
  define(['Utils/Utils', 'UI/Controllers/Folder', 'three'], function(Utils, Folder, Three) {
    var camera, cube, folder, geometry, material, name, parameter, parameters, render, renderer, scene, speed;
    scene = null;
    camera = null;
    renderer = null;
    if (R.three == null) {
      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
      renderer = new THREE.WebGLRenderer();
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setClearColor(0xffffff);
      renderer.domElement.style.width = "100%";
      renderer.domElement.style.height = "100%";
      document.body.appendChild(renderer.domElement);
      R.three = {
        scene: scene,
        camera: camera,
        renderer: renderer
      };
    } else {
      scene = R.three.scene;
      camera = R.three.camera;
      renderer = R.three.renderer;
    }
    parameters = {};
    folder = new Folder('Parameters', false);
    speed = 0.1;
    parameters = {
      speed: {
        type: 'slider',
        label: 'Speed',
        min: 0,
        max: 0.2,
        "default": 0.05,
        onFinishChange: function(value) {
          speed = value;
        }
      }
    };
    for (name in parameters) {
      parameter = parameters[name];
      R.controllerManager.createController(name, parameter, folder);
    }
    geometry = new THREE.BoxGeometry(1, 1, 1);
    material = new THREE.MeshBasicMaterial({
      color: 0x00ff00
    });
    cube = new THREE.Mesh(geometry, material);
    scene.add(cube);
    camera.position.z = 5;
    render = function() {
      requestAnimationFrame(render);
      renderer.render(scene, camera);
      cube.rotation.x += speed;
      cube.rotation.y += speed;
    };
    render();
  });

}).call(this);
