export default {
  setupComponent(args, component) {
   console.log(args.model.username);
   component.set('custom_jerome_username', args.model.username);

  }
}
